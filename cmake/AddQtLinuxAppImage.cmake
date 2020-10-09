# find the Qt root directory
if(NOT Qt5Core_DIR)
  find_package(Qt5Core REQUIRED)
endif()
get_filename_component(QT_LINUX_QT_ROOT "${Qt5Core_DIR}/../../.." ABSOLUTE)
message(STATUS "Found Qt for Linux: ${QT_LINUX_QT_ROOT}")

set(QT_LINUX_QT_ROOT ${QT_LINUX_QT_ROOT})
set(QT_LINUX_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})

find_program(QT_LINUX_DEPLOY_APP linuxdeployqt)
if(QT_LINUX_DEPLOY_APP)
  message(STATUS "Found linuxdeployqt : ${QT_LINUX_DEPLOY_APP}")
else()
  message(WARNING "Fail to find linuxdeployqt")
endif()

include(CMakeParseArguments)

# CMake function that wrap linuxdeployqt (https://github.com/probonopd/linuxdeployqt)
function(add_qt_linux_appimage TARGET)

  set(QT_LINUX_OPTIONS
    ALL
    NO_TRANSLATIONS
    NO_PLUGINS
    NO_STRIP
    NO_APPIMAGE
    NO_COPYRIGHT_FILES
  )

  set(QT_LINUX_ONE_VALUE_ARG
    APP_DIR
    QML_DIR
    VERSION
    VERBOSE_LEVEL
  )

  set(QT_LINUX_MULTI_VALUE_ARG DEPENDS)
  # parse the function arguments
  cmake_parse_arguments(ARGIMG "${QT_LINUX_OPTIONS}" "${QT_LINUX_ONE_VALUE_ARG}" "${QT_LINUX_MULTI_VALUE_ARG}" ${ARGN})

  if(NOT ARGIMG_APP_DIR)
    message(FATAL_ERROR "add_qt_linux_appimage : APP_DIR no specified")
  endif()

  # Check AppDir exists
  if(NOT EXISTS ${ARGIMG_APP_DIR})
    message(FATAL_ERROR "${ARGIMG_APP_DIR} doesn't exists")
  endif()

  set(QT_LINUX_DESKTOP_FILE usr/share/applications/${TARGET}.desktop)

  if(NOT EXISTS ${ARGIMG_APP_DIR}/${QT_LINUX_DESKTOP_FILE})
    message(FATAL_ERROR "${ARGIMG_APP_DIR}/${QT_LINUX_DESKTOP_FILE} doesn't exists")
  endif()

  # Find correct qmake
  set(QT_LINUX_QMAKE_PATH ${QT_LINUX_QT_ROOT}/bin/qmake)
  set(QT_LINUX_QMAKE_OPT -qmake=${QT_LINUX_QMAKE_PATH})

  if(NOT ARGIMG_NO_APPIMAGE)
    set(QT_LINUX_APPIMAGE_OPT -appimage)
  endif()

  # -no-translations
  if(ARGIMG_NO_TRANSLATIONS)
    set(QT_LINUX_TRANSLATIONS_OPT -no-translations)
  endif()

  # -no-plugins
  if(ARGIMG_NO_PLUGINS)
    set(QT_LINUX_PLUGINS_OPT -no-plugins)
  endif()

  # -no-strip
  if(ARGIMG_NO_STRIP)
    set(QT_LINUX_STRIP_OPT -no-strip)
  endif()

  # -no-strip
  if(ARGIMG_NO_COPYRIGHT_FILES)
    set(QT_LINUX_COPYRIGHT_OPT -no-copy-copyright-files)
  endif()

  # -qmldir
  if(ARGIMG_QML_DIR)
    set(QT_LINUX_QML_DIR_OPT -qmldir=${ARGIMG_QML_DIR})
  endif()

  # -verbose
  if(ARGIMG_VERBOSE_LEVEL)
    set(QT_LINUX_VERBOSE_OPT -verbose=${ARGIMG_VERBOSE_LEVEL})
  endif()

  if(ARGIMG_VERSION)
    set(QT_LINUX_APP_VERSION ${ARGIMG_VERSION})
  else()
    if(PROJECT_VERSION)
      set(QT_LINUX_APP_VERSION ${PROJECT_VERSION})
    else()
      set(QT_LINUX_APP_VERSION "1.0.0")
    endif()
  endif()

  if(ARGIMG_ALL)
    set(QT_LINUX_ALL ALL)
  endif()

  set(QT_LINUX_TARGET ${TARGET}AppImage)

  message(STATUS "ARGIMG_APP_DIR : ${ARGIMG_APP_DIR}")
  message(STATUS "QT_LINUX_TARGET : ${QT_LINUX_TARGET}")
  message(STATUS "QT_LINUX_DEPLOY_APP : ${QT_LINUX_DEPLOY_APP}")
  message(STATUS "QT_LINUX_APPIMAGE_OPT : ${QT_LINUX_APPIMAGE_OPT}")
  message(STATUS "QT_LINUX_QML_DIR_OPT : ${QT_LINUX_QML_DIR_OPT}")
  message(STATUS "QT_LINUX_TRANSLATIONS_OPT : ${QT_LINUX_TRANSLATIONS_OPT}")
  message(STATUS "QT_LINUX_PLUGINS_OPT : ${QT_LINUX_PLUGINS_OPT}")
  message(STATUS "QT_LINUX_STRIP_OPT : ${QT_LINUX_STRIP_OPT}")
  message(STATUS "QT_LINUX_VERBOSE_OPT : ${QT_LINUX_VERBOSE_OPT}")
  message(STATUS "QT_LINUX_APP_VERSION : ${QT_LINUX_APP_VERSION}")

  # Call linuxdeployqt
  add_custom_target(${QT_LINUX_TARGET}
    ${QT_LINUX_ALL}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>
    DEPENDS ${TARGET} ${ARGIMG_DEPENDS}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${ARGIMG_APP_DIR} ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/AppDir
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${TARGET}> ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/AppDir/usr/bin/$<TARGET_FILE_NAME:${TARGET}>
    COMMAND ${CMAKE_COMMAND} -E env VERSION=${QT_LINUX_APP_VERSION}
      ${QT_LINUX_DEPLOY_APP}
      # Desktop file
      ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/AppDir/${QT_LINUX_DESKTOP_FILE}
      # Options
      ${QT_LINUX_APPIMAGE_OPT}
      ${QT_LINUX_QML_DIR_OPT}
      ${QT_LINUX_TRANSLATIONS_OPT}
      ${QT_LINUX_PLUGINS_OPT}
      ${QT_LINUX_STRIP_OPT}
      ${QT_LINUX_COPYRIGHT_OPT}
      ${QT_LINUX_VERBOSE_OPT}

    COMMENT "Deploy AppImage with ${QT_LINUX_DEPLOY_APP}"
  )

endfunction()