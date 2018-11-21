if(NOT WIN32)
  if(KODI_DEPENDSBUILD)
    set(_dvdlibs dvdread dvdnav)
    set(_handlevars LIBDVD_INCLUDE_DIRS DVDREAD_LIBRARY DVDNAV_LIBRARY)
    if(ENABLE_DVDCSS)
      list(APPEND _dvdlibs libdvdcss)
      list(APPEND _handlevars DVDCSS_LIBRARY)
    endif()

#    if(PKG_CONFIG_FOUND)
      pkg_check_modules(PC_DVD ${_dvdlibs} QUIET)
#    endif()

    find_path(LIBDVD_INCLUDE_DIRS dvdnav/dvdnav.h PATHS ${PC_DVD_INCLUDE_DIRS})
    find_library(DVDREAD_LIBRARY NAMES dvdread libdvdread PATHS ${PC_DVD_dvdread_LIBDIR})
    find_library(DVDNAV_LIBRARY NAMES dvdnav libdvdnav PATHS ${PC_DVD_dvdnav_LIBDIR})
    if(ENABLE_DVDCSS)
      find_library(DVDCSS_LIBRARY NAMES dvdcss libdvdcss PATHS ${PC_DVD_libdvdcss_LIBDIR})
    endif()

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(LIBDVD REQUIRED_VARS ${_handlevars})
    if(LIBDVD_FOUND)
      add_library(dvdnav UNKNOWN IMPORTED)
      set_target_properties(dvdnav PROPERTIES
                                   FOLDER "External Projects"
                                   IMPORTED_LOCATION "${DVDNAV_LIBRARY}")

      add_library(dvdread UNKNOWN IMPORTED)
      set_target_properties(dvdread PROPERTIES
                                    FOLDER "External Projects"
                                    IMPORTED_LOCATION "${DVDREAD_LIBRARY}")
      add_library(dvdcss UNKNOWN IMPORTED)
      set_target_properties(dvdcss PROPERTIES
                                   FOLDER "External Projects"
                                   IMPORTED_LOCATION "${DVDCSS_LIBRARY}")

      set(_linklibs ${DVDREAD_LIBRARY})
      if(ENABLE_DVDCSS)
        list(APPEND _linklibs ${DVDCSS_LIBRARY})
      endif()
    ## FIXME
      core_link_library(${DVDNAV_LIBRARY} system/players/VideoPlayer/libdvdnav dvdnav archives "${_linklibs}")
      set(LIBDVD_LIBRARIES ${DVDNAV_LIBRARY})
      mark_as_advanced(LIBDVD_INCLUDE_DIRS LIBDVD_LIBRARIES)
    endif()
  else()
    set(dvdlibs libdvdread libdvdnav)
    if(ENABLE_DVDCSS)
      list(APPEND dvdlibs libdvdcss)
    endif()
    foreach(dvdlib ${dvdlibs})
      file(GLOB VERSION_FILE ${CORE_SOURCE_DIR}/tools/depends/target/${dvdlib}/DVD*-VERSION)
      file(STRINGS ${VERSION_FILE} VER)
      string(REGEX MATCH "VERSION=[^ ]*$.*" ${dvdlib}_VER "${VER}")
      list(GET ${dvdlib}_VER 0 ${dvdlib}_VER)
      string(SUBSTRING "${${dvdlib}_VER}" 8 -1 ${dvdlib}_VER)
      string(REGEX MATCH "BASE_URL=([^ ]*)" ${dvdlib}_BASE_URL "${VER}")
      list(GET ${dvdlib}_BASE_URL 0 ${dvdlib}_BASE_URL)
      string(SUBSTRING "${${dvdlib}_BASE_URL}" 9 -1 ${dvdlib}_BASE_URL)
      string(TOUPPER ${dvdlib} DVDLIB)

      # allow user to override the download URL with a local tarball
      # needed for offline build envs
      # allow upper and lowercase var name
      if(${dvdlib}_URL)
        set(${DVDLIB}_URL ${${dvdlib}_URL})
      endif()
      if(${DVDLIB}_URL)
        get_filename_component(${DVDLIB}_URL "${${DVDLIB}_URL}" ABSOLUTE)
      else()
        set(${DVDLIB}_URL ${${dvdlib}_BASE_URL}/archive/${${dvdlib}_VER}.tar.gz)
      endif()
      if(VERBOSE)
        message(STATUS "${DVDLIB}_URL: ${${DVDLIB}_URL}")
      endif()
    endforeach()

    set(DVDREAD_CFLAGS "${DVDREAD_CFLAGS} -I${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/libdvd/include")
    if(CMAKE_CROSSCOMPILING)
      set(EXTRA_FLAGS "CC=${CMAKE_C_COMPILER}")
    endif()

    if(APPLE)
      set(CMAKE_LD_FLAGS "-framework IOKit -framework CoreFoundation")
    endif()

    set(HOST_ARCH ${ARCH})
    if(CORE_SYSTEM_NAME STREQUAL android)
      if(ARCH STREQUAL arm)
        set(HOST_ARCH arm-linux-androideabi)
      elseif(ARCH STREQUAL aarch64)
        set(HOST_ARCH aarch64-linux-android)
      elseif(ARCH STREQUAL i486-linux)
        set(HOST_ARCH i686-linux-android)
      endif()
    endif()

    if(ENABLE_DVDCSS)
#      set(DVDCSS_LIBRARY ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/libdvd/lib/libdvdcss.a)
    endif()

    set(DVDREAD_CFLAGS "-D_XBMC -I${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/libdvd/include")
    if(ENABLE_DVDCSS)
      set(DVDREAD_CFLAGS "${DVDREAD_CFLAGS} -DHAVE_DVDCSS_DVDCSS_H")
    endif()

    set(DVDREAD_LIBRARY ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/libdvd/lib/libdvdread.a)
    if(ENABLE_DVDCSS)
      add_dependencies(dvdread dvdcss)
    endif()

    set_target_properties(dvdread PROPERTIES FOLDER "External Projects")

    if(ENABLE_DVDCSS)
      set(DVDNAV_LIBS -ldvdcss)
    endif()

    set(DVDNAV_LIBRARY ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/libdvd/lib/libdvdnav.a)
    add_dependencies(dvdnav dvdread)
    set_target_properties(dvdnav PROPERTIES FOLDER "External Projects")

    set(_dvdlibs ${DVDREAD_LIBRARY} ${DVDCSS_LIBRARY})

    set(LIBDVD_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/libdvd/include)
    set(LIBDVD_LIBRARIES ${DVDNAV_LIBRARY} ${DVDREAD_LIBRARY})
    if(ENABLE_DVDCSS)
      list(APPEND LIBDVD_LIBRARIES ${DVDCSS_LIBRARY})
    endif()
    set(LIBDVD_LIBRARIES ${LIBDVD_LIBRARIES} CACHE STRING "libdvd libraries" FORCE)
    set(LIBDVD_FOUND 1 CACHE BOOL "libdvd found" FORCE)
    endif()
else()
  # Dynamically loaded on Windows
  find_path(LIBDVD_INCLUDE_DIR dvdcss/dvdcss.h PATHS ${CORE_SOURCE_DIR}/lib/libdvd/include)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LIBDVD REQUIRED_VARS LIBDVD_INCLUDE_DIR)

  if(LIBDVD_FOUND)
    set(LIBDVD_INCLUDE_DIRS ${LIBDVD_INCLUDE_DIR})

    add_custom_target(dvdnav)
    set_target_properties(dvdnav PROPERTIES FOLDER "External Projects")
  endif()

  mark_as_advanced(LIBDVD_INCLUDE_DIR)
endif()
