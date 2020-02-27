include(MCRuler)

add_library(test test1.cpp test2.c test_nested/test3.cpp)
target_compile_features(test PRIVATE cxx_std_17)
target_compile_options(test PRIVATE -msse3)
target_link_libraries(test PUBLIC mc_ruler)

mc_measure(
    test
    SOURCES
    test1.cpp
    test2.c
    test_nested/test3.cpp
    LLVM_MCA_FLAGS
)
