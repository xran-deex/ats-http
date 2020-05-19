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
##################################################################################
#
# ATS_FILES 
#
# This is a list of files begin compiled.
#
##################################################################################
SET (ATS_FILES)
##################################################################################
#
# ATS_DEPGEN (OUTPUT SRC)
#
# Generate dependencies for a single source file.
# Call it like this: ATS_DEPGEN (A_VAR ${A_SINGLE_FILE})
#
# The output is a STRING, not a LIST.
#
##################################################################################
MACRO (ATS_DEPGEN OUTPUT SRC)
	IF (${ARGC} GREATER 2)
		MESSAGE (FATAL_ERROR "Only support one source file!")
	ENDIF ()
	IF (ATS_VERBOSE)
		MESSAGE (STATUS "*********************************")
		MESSAGE (STATUS "Computing dependencies for ${SRC}")
	ENDIF ()
	# convert to absolute path
	ATS_AUX_UNIFY_PATH ("${SRC}" SRC)
	# for display
	ATS_AUX_LIST_TO_STRING ("${ATS_INCLUDE}" _TEXT_INCLUDE)
	# execute atsopt
	IF (SRC MATCHES "\\.dats$")
		IF (ATS_VERBOSE)
			MESSAGE (STATUS "${ATSOPT} ${_TEXT_INCLUDE} --depgen --dynamic ${SRC}")
		ENDIF ()
		EXECUTE_PROCESS (
			COMMAND ${ATSOPT} ${ATS_INCLUDE} --depgen --dynamic ${SRC}
			RESULT_VARIABLE _ATS_DEPGEN_RESULT
			OUTPUT_VARIABLE _ATS_DEPGEN_OUTPUT
			ERROR_VARIABLE _ATS_DEPGEN_ERROR
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_STRIP_TRAILING_WHITESPACE)
	ELSEIF (SRC MATCHES "\\.sats$")
		IF (ATS_VERBOSE)
			MESSAGE (STATUS "${ATSOPT} ${_TEXT_INCLUDE} --depgen --static ${SRC}")
		ENDIF ()
		EXECUTE_PROCESS (
			COMMAND ${ATSOPT} ${ATS_INCLUDE} --depgen --static ${SRC}
			RESULT_VARIABLE _ATS_DEPGEN_RESULT
			OUTPUT_VARIABLE _ATS_DEPGEN_OUTPUT
			ERROR_VARIABLE _ATS_DEPGEN_ERROR
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_STRIP_TRAILING_WHITESPACE)
	ENDIF ()
	# it is determined by atsopt -dep1 output. No spaces allowed in any path.
	STRING (REGEX REPLACE "^.*:" "" ${OUTPUT} "${_ATS_DEPGEN_OUTPUT}")
    STRING (STRIP "${${OUTPUT}}" ${OUTPUT})
    # if it has some dependencies
   	IF (NOT "${${OUTPUT}}" STREQUAL "")
    	ATS_AUX_STRING_TO_LIST (${${OUTPUT}} ${OUTPUT})
    	ATS_DEPGEN_C (${OUTPUT})
    ENDIF ()
    # convert to absolute paths
    ATS_AUX_TO_ABSOLUTE_PATH (${${OUTPUT}} ${OUTPUT})
    IF (ATS_VERBOSE)
	    FOREACH (_E ${${OUTPUT}})
	    	MESSAGE (STATUS "Result: ${_E}")
	    ENDFOREACH ()
	ENDIF ()
    UNSET (_E)
	UNSET (_ATS_DEPGEN_RESULT)
	UNSET (_ATS_DEPGEN_OUTPUT)
	UNSET (_ATS_DEPGEN_ERROR)
	UNSET (_TEXT_INCLUDE)
ENDMACRO ()
##################################################################################
#
# ATS_DEPGEN_C (DEP)
#
# Expend dependencies for generated C files.
#
# For example: 
# 	If we have 		1.sats <- 2.sats
#	Then we add 	1_sats.c <- 2_sats.c
#
# This is useful when 1.sats inludes a HATS file. When the HATS file updates, 
# 1.sats is not changed, but 1_sats.c is changed. And since 2.sats depends on
# 1.sats and it is not changed, 2_sats.c is not recompiled. However, it should 
# be recompiled since the actual meaning of 1.sats has been changed.
#
# The output is a STRING, not a LIST.
#
##################################################################################
MACRO (ATS_DEPGEN_C DEP)
	FOREACH (_E ${${DEP}})
		IF (_E MATCHES "\\.sats$|\\.dats$")
			ATS_AUX_GET_C_FILE_NAME ("${_E}" _C)
			LIST (APPEND ${DEP} "${_C}")
			LIST (FIND ATS_FILES "${_E}" _FOUND)
			IF (_FOUND EQUAL -1)
				IF (NOT EXISTS ${_C})
					EXECUTE_PROCESS (
						COMMAND touch ${_C}
						RESULT_VARIABLE _ATS_TC_RESULT
						OUTPUT_VARIABLE _ATS_TC_OUTPUT
						ERROR_VARIABLE _ATS_TC_ERROR
						OUTPUT_STRIP_TRAILING_WHITESPACE
						ERROR_STRIP_TRAILING_WHITESPACE)
					MESSAGE (STATUS "Executed: touch ${_C}")
				ENDIF()
			ENDIF ()
		ENDIF ()
	ENDFOREACH ()
ENDMACRO ()
MACRO (ATS_TYPE_CHECK SRC)
	EXECUTE_PROCESS (
		COMMAND atscc -tc ${SRC}
		RESULT_VARIABLE _ATS_TC_RESULT
		OUTPUT_VARIABLE _ATS_TC_OUTPUT
		ERROR_VARIABLE _ATS_TC_ERROR
		OUTPUT_STRIP_TRAILING_WHITESPACE
		ERROR_STRIP_TRAILING_WHITESPACE)
	MESSAGE (STATUS ${_ATS_TC_OUTPUT})
	UNSET (_ATS_TC_RESULT)
	UNSET (_ATS_TC_OUTPUT)
	UNSET (_ATS_TC_ERROR)
ENDMACRO ()
##################################################################################
#
# ATS_AUX_UNIFY_PATH (IN OUT)
#
# Convert IN into absolute path and save it into OUT.
# IN is expected to be a relative path starting from ${CMAKE_CURRENT_LIST_DIR}
# IN should be a single file.
#
##################################################################################
MACRO (ATS_AUX_UNIFY_PATH IN OUT)
	# resolve soft/hard link? YES!
	GET_FILENAME_COMPONENT (${OUT} "${IN}" REALPATH)
	# THIS CAUSE BUGS WHEN IT IS SOFT/HARD LINK
	# relative path to CMAKE_CURRENT_LIST_DIR
	# FILE (RELATIVE_PATH ${OUT} "${CMAKE_CURRENT_LIST_DIR}" "${${OUT}}")
	# get the output 
	# SET (${OUT} "${CMAKE_CURRENT_LIST_DIR}/${${OUT}}")
	# strip spaces
	STRING (STRIP "${${OUT}}" ${OUT})
ENDMACRO ()
##################################################################################
#
# ATS_COMPILE (OUTPUT ...)
#
# Compile all the sources into C files, and store output C filenames (full path)
# into OUTPUT as a list. Dependencies are resolved automatically.
#
# Note, OUTPUT is a LIST, not a STRING.
#
##################################################################################
MACRO (ATS_COMPILE OUTPUT)
	IF (NOT "${OUTPUT}" MATCHES "^${OUTPUT}$")
		MESSAGE (STATUS "Parameter should be a variable instead of the value of variable!")
		MESSAGE (FATAL_ERROR "Example: ATS_COMPILE (C_OUTPUT, ${SOURCE_FILES})")
	ENDIF ()
	SET (_ATS_FILES ${ARGN})
	# set global variable ATS_FILES to record files being compiled.
	FOREACH (_ATS_FILE ${_ATS_FILES})
		ATS_AUX_UNIFY_PATH ("${_ATS_FILE}" _ATS_FILE)
		LIST (APPEND ATS_FILES "${_ATS_FILE}")
	ENDFOREACH ()
	SET (_C_OUTPUT)
	# iterate all files
	FOREACH (_ATS_FILE ${_ATS_FILES})
		# convert to absolute path
		ATS_AUX_UNIFY_PATH ("${_ATS_FILE}" _ATS_FILE)
		# get dependencies
		ATS_DEPGEN (_DEPENDENCY "${_ATS_FILE}")
		# for static files
		IF (_ATS_FILE MATCHES "\\.sats$")
			ATS_AUX_GET_C_FILE_NAME ("${_ATS_FILE}" _SATS_C)
			IF (ATS_VERBOSE)
				MESSAGE (STATUS "Generating target ${_SATS_C}")
			ENDIF ()
			ADD_CUSTOM_COMMAND (
			    OUTPUT ${_SATS_C} 
			    COMMAND ${ATSOPT} ${ATS_INCLUDE} --output ${_SATS_C} --static ${_ATS_FILE}
			    DEPENDS ${_ATS_FILE} ${_DEPENDENCY}
		  	)
		  	LIST (APPEND _C_OUTPUT "${_SATS_C}")
		# for dynamic files
		ELSEIF (_ATS_FILE MATCHES "\\.dats$")
			ATS_AUX_GET_C_FILE_NAME ("${_ATS_FILE}" _DATS_C)
			IF (ATS_VERBOSE)
				MESSAGE (STATUS "Generating target ${_DATS_C}")
			ENDIF ()
			ADD_CUSTOM_COMMAND (
			    OUTPUT ${_DATS_C} 
			    COMMAND ${ATSOPT} ${ATS_INCLUDE} --output ${_DATS_C} --dynamic ${_ATS_FILE}
			    DEPENDS ${_ATS_FILE} ${_DEPENDENCY}
		  	)
		  	LIST (APPEND _C_OUTPUT "${_DATS_C}")
		ELSE ()
			MESSAGE (STATUS "Not SATS/DATS file, ignored - ${_ATS_FILE}")
		ENDIF ()
	ENDFOREACH()
	SET (${OUTPUT} ${_C_OUTPUT})
	UNSET (_ATS_FILES)
	UNSET (_ATS_FILE)
	UNSET (_C_OUTPUT)
	UNSET (_SATS_C)
	UNSET (_DATS_C)
	UNSET (_PREFIX_SRC)
	UNSET (_DEPENDENCY)
ENDMACRO ()
MACRO (ATS_INCLUDE_RESET)
	UNSET (ATS_INCLUDE)
	SET (ATS_INCLUDE)
ENDMACRO ()
##################################################################################
#
# ATS_INCLUDE (...)
#
# Side Effect: ATS_INCLUDE
#
# Append all paths as INCLUDE paths, for ATSCC/ATSOPT to find SATS/HATS files.
# It operates ATS_INCLUDE, which is a LIST.
#
##################################################################################
MACRO (ATS_INCLUDE)
	FOREACH (_PATH ${ARGN})
		ATS_AUX_UNIFY_PATH ("${_PATH}" _PATH)
		LIST (APPEND _INCLUDE -IATS "${_PATH}")
	ENDFOREACH ()
	LIST (APPEND ATS_INCLUDE ${_INCLUDE})
	STRING (STRIP "${ATS_INCLUDE}" ATS_INCLUDE)
	UNSET (_INCLUDE)
	UNSET (_PATH)
ENDMACRO ()
MACRO (ATS_AUX_LIST_TO_STRING IN OUT)
	IF (${ARGC} GREATER 2)
		MESSAGE (FATAL_ERROR "No more than 2 arguments!")
	ENDIF ()
	UNSET (${OUT})
	FOREACH (_E ${IN})
		SET (${OUT} "${${OUT}} ${_E}")
	ENDFOREACH ()
	STRING (STRIP "${${OUT}}" ${OUT})
	UNSET (_E)
ENDMACRO ()
##################################################################################
#
# ATS_AUX_STRING_TO_LIST (IN OUT)
#
# Requirement: The string should be space separated. So, no space is allowed in
# an element unless it is quoted according to UNIX standard.
#
#
# TODO: UNIX_COMMAND? WINDOWS_COMMAND?
#
##################################################################################
MACRO (ATS_AUX_STRING_TO_LIST IN OUT)
	IF (${ARGC} EQUAL 2)
		#STRING (REGEX REPLACE "[ ]" ";" _TEMP "${IN}")
		#SET (${OUT} ${_TEMP})
		#UNSET (_TEMP)
		# Workaround for CMake 2.6
	    IF (${CMAKE_VERSION} VERSION_LESS "2.8.3")
                SET (${OUT} "${IN}")
                SEPARATE_ARGUMENTS (${OUT})
        ELSE ()
                SEPARATE_ARGUMENTS (${OUT} UNIX_COMMAND "${IN}")
        ENDIF ()
        
	ENDIF ()
	
ENDMACRO ()
##################################################################################
#
# ATS_AUX_GET_C_FILE_NAME (IN OUT)
#
# Compute a corresponing C file name for a SATS/DATS file
#
##################################################################################
MACRO (ATS_AUX_GET_C_FILE_NAME IN OUT)
	STRING(REGEX REPLACE "\\.sats$" "_sats.c" ${OUT} "${IN}")	
	STRING(REGEX REPLACE "\\.dats$" "_dats.c" ${OUT} "${${OUT}}")
ENDMACRO ()
##################################################################################
#
# ATS_AUX_TO_ABSOLUTE_PATH (OUTOUT ...)
#
# Compute absolute paths for a list of files.
#
##################################################################################
MACRO (ATS_AUX_TO_ABSOLUTE_PATH OUTPUT)
	UNSET (${OUTPUT})
	FOREACH (_E ${ARGN})
		GET_FILENAME_COMPONENT (_O "${_E}" REALPATH)
		LIST (APPEND ${OUTPUT} "${_O}")
	ENDFOREACH ()
	UNSET (_E)
	UNSET (_O)
ENDMACRO ()
MACRO (ATS_IMPORT PACKAGE)
	MESSAGE (STATUS *********************************)
	IF (NOT ATS_REPO)
		MESSAGE (FATAL_ERROR "ATS_IMPORT needs \${ATS_REPO} to be set!")
	ENDIF ()
	MESSAGE (STATUS "Importing ${PACKAGE} from repository ${ATS_REPO}")
	INCLUDE (ExternalProject)
	# The ${PACKAGE}_DIR will be exported after the call to this macro
	SET (PACKAGE_DIR ${PACKAGE}_DIR)
	FIND_PATH (${PACKAGE_DIR}	
		${PACKAGE}
		PATHS ${ATS_REPO})
	# The ${PACKAGE}_FOUND will be exported if it is found
	INCLUDE (FindPackageHandleStandardArgs)
	FIND_PACKAGE_HANDLE_STANDARD_ARGS (${PACKAGE} DEFAULT_MSG ${PACKAGE_DIR})
	IF (NOT ${PACKAGE}_FOUND)
		MESSAGE (FATAL_ERROR "${PACKAGE} importing failed!")
	ENDIF ()
	GET_FILENAME_COMPONENT (${PACKAGE_DIR} ${${PACKAGE_DIR}}/${PACKAGE} REALPATH)
	MESSAGE (STATUS "Found: ${${PACKAGE_DIR}}")
	EXTERNALPROJECT_ADD (
	   ${PACKAGE}
	   PREFIX ${${PACKAGE_DIR}}/build
	   SOURCE_DIR ${${PACKAGE_DIR}}
	   BINARY_DIR ${${PACKAGE_DIR}}/build
	)
	IF (NOT EXISTS "${${PACKAGE_DIR}}/${PACKAGE}_IMPORT.cmake")
		EXECUTE_PROCESS (
			COMMAND ${CMAKE_COMMAND} ..
			WORKING_DIRECTORY ${${PACKAGE_DIR}}/build)
	ENDIF ()
	INCLUDE ("${${PACKAGE_DIR}}/${PACKAGE}_IMPORT.cmake")
ENDMACRO ()
##################################################################################
#
# ATS_EXPORT (
#	PACKAGE
#	INCLUDE_DIRS_C ...
#	INCLUDE_DIRS_ATS ...
#	LINK_DIRS ...)
#
# This will create an ${PACKAGE_IMPORT.cmake under ${CMAKE_CURRENT_LIST_DIR}
#
##################################################################################
MACRO (ATS_EXPORT PACKAGE)
	SET (_FILE "${CMAKE_CURRENT_LIST_DIR}/${PACKAGE}_IMPORT.cmake")
	FILE (WRITE ${_FILE} "#AUTOGENERATED\n")
	FOREACH (_ARG ${ARGN})
		IF ("${_ARG}" STREQUAL "INCLUDE_DIRS_C")
			SET (_STATE "INCLUDE_DIRS_C")
		ELSEIF ("${_ARG}" STREQUAL "INCLUDE_DIRS_ATS")
			SET (_STATE "INCLUDE_DIRS_ATS")
		ELSEIF ("${_ARG}" STREQUAL "LINK_DIRS")
			SET (_STATE "LINK_DIRS")
		ELSE ()
			ATS_AUX_UNIFY_PATH ("${_ARG}" _ARG)
			IF ("${_STATE}" STREQUAL "INCLUDE_DIRS_C")
				FILE (APPEND ${_FILE} "INCLUDE_DIRECTORIES (${_ARG})\n")
			ELSEIF ("${_STATE}" STREQUAL "INCLUDE_DIRS_ATS")
				FILE (APPEND ${_FILE} "ATS_INCLUDE (${_ARG})\n")
			ELSEIF ("${_STATE}" STREQUAL "LINK_DIRS")
				FILE (APPEND ${_FILE} "LINK_DIRECTORIES (${_ARG})\n")
			ENDIF ()
		ENDIF ()
	ENDFOREACH ()
ENDMACRO ()
