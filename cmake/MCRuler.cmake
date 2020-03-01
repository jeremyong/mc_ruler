# Properties reference: https://cmake.org/cmake/help/latest/manual/cmake-properties.7.html

function(mc_ruler TARGET)
    cmake_parse_arguments(PARSE_ARGV 1 MC_RULER "" "" "SOURCES;LLVM_MCA_FLAGS")

    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        set(VALID_CXX_COMPILER ON)
        if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
            set(TEMP_CXX_SUFFIX "")
        else()
            set(TEMP_CXX_SUFFIX ".cpp")
        endif()
    else()
        set(VALID_CXX_COMPILER OFF)
    endif()

    if(CMAKE_C_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        set(VALID_CC_COMPILER ON)
        if(CMAKE_C_COMPILER_ID MATCHES "Clang")
            set(TEMP_C_SUFFIX "")
        else()
            set(TEMP_C_SUFFIX ".c")
        endif()
    else()
        set(VALID_CC_COMPILER OFF)
    endif()

    if(NOT (VALID_CXX_COMPILER OR VALID_CC_COMPILER))
        message(WARNING "Not using supported C or CXX compiler. MC ruler is deactivated")
        return()
    endif()

    get_target_property(TARG_COMP_OPTS ${TARGET} COMPILE_OPTIONS)
    get_target_property(TARG_COMP_DEFS ${TARGET} COMPILE_DEFINITIONS)
    get_target_property(TARG_LIBS ${TARGET} LINK_LIBRARIES)
    get_target_property(TARG_LINK_OPTS ${TARGET} LINK_OPTIONS)
    get_target_property(TARG_LINK_DIRS ${TARGET} LINK_DIRECTORIES)
    get_target_property(TARG_INC_DIRS ${TARGET} INCLUDE_DIRECTORIES)
    get_target_property(TARG_COMP_FEATURES ${TARGET} COMPILE_FEATURES)
    get_target_property(TARG_BIN_DIR ${TARGET} BINARY_DIR)
    get_target_property(TARG_SOURCE_DIR ${TARGET} SOURCE_DIR)

    if(NOT TARG_COMP_OPTS)
        set(TARG_COMP_OPTS "")
    endif()
    if(NOT TARG_COMP_DEFS)
        set(TARG_COMP_DEFS "")
    endif()
    if(NOT TARG_LIBS)
        set(TARG_LIBS "")
    endif()
    if(NOT TARG_LINK_OPTS)
        set(TARG_LINK_OPTS "")
    endif()
    if(NOT TARG_LINK_DIRS)
        set(TARG_LINK_DIRS "")
    endif()
    if(NOT TARG_INC_DIRS)
        set(TARG_INC_DIRS "")
    endif()
    if(NOT TARG_COMP_FEATURES)
        set(TARG_COMP_FEATURES "")
    endif()

    set(OUTPUT_DIR ${PROJECT_BINARY_DIR}/mc_ruler/${TARGET})
    set(OUTPUT_LIB_DIR ${OUTPUT_DIR}/libs)
    file(MAKE_DIRECTORY ${OUTPUT_DIR})
    file(MAKE_DIRECTORY ${OUTPUT_DIR}/libs)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR}/libs)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR}/libs)

    foreach(SOURCE ${MC_RULER_SOURCES})
        get_filename_component(SOURCE_DIR ${SOURCE} DIRECTORY)
        get_filename_component(SOURCE_FILE ${SOURCE} NAME)
        if(NOT SOURCE_DIR)
            set(SOURCE_REL "")
        else()
            set(SOURCE_REL "${SOURCE_DIR}/")
        endif()
        get_filename_component(SOURCE_NAME ${SOURCE} NAME_WLE)
        file(MAKE_DIRECTORY ${OUTPUT_DIR}/${SOURCE_DIR})

        get_source_file_property(LANG ${SOURCE} LANGUAGE)
        if(LANG STREQUAL "CXX" AND NOT VALID_CXX_COMPILER)
            message(
                WARNING
                "Not using Clang C++ compiler. ${SOURCE} omitted from mc ruler measurement"
            )
            continue()
        elseif(LANG STREQUAL "C" AND NOT VALID_CC_COMPILER)
            message(
                WARNING
                "Not using Clang C compiler. ${SOURCE} omitted from mc ruler measurement"
            )
            continue()
        endif()
        if(LANG STREQUAL "CXX")
            set(TEMP_SUFFIX ${TEMP_CXX_SUFFIX})
        else()
            set(TEMP_SUFFIX ${TEMP_C_SUFFIX})
        endif()

        # Add a new target for this source file, specifically to emit assembly
        # and run llvm-mca on the saved temporary
        set(SOURCE_TARGET "mc_measure_${SOURCE_NAME}")
        add_library(${SOURCE_TARGET} ${SOURCE})
        target_include_directories(
            ${SOURCE_TARGET}
            PRIVATE
            ${TARG_INC_DIRS}
        )
        target_compile_options(
            ${SOURCE_TARGET}
            PRIVATE
            ${TARG_COMP_OPTS}
            -save-temps=obj
        )
        target_compile_definitions(
            ${SOURCE_TARGET}
            PRIVATE
            ${TARGET_COMP_DEFS}
            MC_RULER_ENABLED
        )
        target_link_directories(
            ${SOURCE_TARGET}
            PRIVATE
            ${TARGET_LINK_DIRS}
        )
        target_link_libraries(
            ${SOURCE_TARGET}
            PRIVATE
            ${TARG_LIBS}
        )
        target_link_options(
            ${SOURCE_TARGET}
            PRIVATE
            ${TARG_LINK_OPTS}
        )
        target_compile_features(
            ${SOURCE_TARGET}
            PRIVATE
            ${TARG_COMP_FEATURES}
        )
        add_custom_command(
            TARGET ${SOURCE_TARGET}
            POST_BUILD
            COMMAND
            llvm-mca
            ARGS
            -o ${OUTPUT_DIR}/${SOURCE_DIR}/${SOURCE_NAME}.mcr
            ${MC_RULER_LLVM_MCA_FLAGS}
            ${TARG_BIN_DIR}/CMakeFiles/${SOURCE_TARGET}.dir/${SOURCE_REL}${SOURCE_NAME}${TEMP_SUFFIX}.s
            BYPRODUCTS ${OUTPUT_DIR}/${SOURCE_DIR}/${SOURCE_NAME}.mcr
            WORKING_DIRECTORY
            ${OUTPUT_DIR}
            VERBATIM
        )
    endforeach()
endfunction()