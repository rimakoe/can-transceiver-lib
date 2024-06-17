.PHONY: all build cmake clean format

BUILD_DIR := build
BUILD_TYPE ?= Debug
ARCH := x86_64

all: build

${BUILD_DIR}/Makefile: 
	$(info Checking desired architecture)
ifeq ($(ARCH), arm)
	cmake \
		-B${BUILD_DIR} \
		-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
		-DCMAKE_TOOLCHAIN_FILE=gcc-arm-none-eabi.cmake \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON
endif
ifeq ($(ARCH), x86_64)
	cmake \
		-B${BUILD_DIR} \
		-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON
endif

cmake: ${BUILD_DIR}/Makefile

build: cmake
	$(MAKE) -C ${BUILD_DIR} --no-print-directory

install: cmake
	$(MAKE) -C ${BUILD_DIR} --no-print-directory install

SRCS := $(shell find . -name '*.[ch]' -or -name '*.[ch]pp')
format: $(addsuffix .format,${SRCS})

%.format: %
	clang-format -i $<

clean:
	rm -rf $(BUILD_DIR)
