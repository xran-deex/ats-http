##*********************************************************************##
##                                                                     ##
##                              ATS-CMake                              ##
##                                                                     ##
##*********************************************************************##
##
## ATS-CMake - CMake modules for ATS projects.
## Copyright (c) 2012-2013 Hanwen Wu <hwwu AT bu DOT edu>
## All rights reserved.
##
## ATS-CMake is a free software under MIT license. You can use it as long
## as you acknowledge my original work.
##
## The MIT License (MIT)
## Copyright (c) 2012-2013 Hanwen Wu <hwwu AT bu DOT edu>
## 
## Permission is hereby granted, free of charge, to any person obtaining 
## a copy of this software and associated documentation files (the 
## "Software"), to deal in the Software without restriction, including 
## without limitation the rights to use, copy, modify, merge, publish, 
## distribute, sublicense, and/or sell copies of the Software, and to permit 
## persons to whom the Software is furnished to do so, subject to the following 
## conditions:
## 
## The above copyright notice and this permission notice shall be included in all 
## copies or substantial portions of the Software.
## 
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
## THE SOFTWARE.
##
CMAKE_MINIMUM_REQUIRED (VERSION 2.8)
MESSAGE (STATUS "*********************************")
MESSAGE (STATUS "Finding ATS")
INCLUDE (ATSCC)
FIND_PATH (ATS_HOME
	NAMES bin/patscc
	PATHS ENV PATSHOME)
SET (ATS_INCLUDE_DIR ${ATS_HOME} ${ATS_HOME}/ccomp/runtime)
SET (ATS_LIBRARY ${ATS_HOME}/ccomp/lib)
INCLUDE (FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS (ATS DEFAULT_MSG ATS_LIBRARY ATS_INCLUDE_DIR ATS_HOME)
SET (ATS_INCLUDE_DIRS ${ATS_INCLUDE_DIR})
SET (ATS_LIBRARIES ${ATS_LIBRARY})
MARK_AS_ADVANCED (ATS_INCLUDE_DIR ATS_LIBRARY)
SET (ATSCC ${ATS_HOME}/bin/patscc)
SET (ATSOPT ${ATS_HOME}/bin/patsopt)
SET (CMAKE_C_COMPILER patscc)
SET (ATSCC_FLAGS)
MESSAGE (STATUS "ATS Home: ${ATS_HOME}")
MESSAGE (STATUS "Includes: ${ATS_INCLUDE_DIRS}")
MESSAGE (STATUS "Libraries: ${ATS_LIBRARIES}")
SET (ATS_VERBOSE False)
# Workaround for CMake 2.6
IF ("${CMAKE_CURRENT_LIST_DIR}" STREQUAL "")
	SET (CMAKE_CURRENT_LIST_DIR ${CMAKE_CURRENT_SOURCE_DIR})
ENDIF ()
