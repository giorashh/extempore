
# pre-compile some standard Extempore libraries for faster loading

# if [ -z "$EXT_LLVM_DIR" ] && [ ! -d "/usr/local/Cellar/extempore-llvm/3.4.1" ] ; then
#     echo -e "\033[0;31mError\033[0;00m: You need to set the \033[0;32mEXT_LLVM_DIR\033[0;00m environment variable to point to your (Extempore) LLVM directory."
#     exit 2
# fi

ifeq ($(shell uname), Linux)
	SHLIB_EXT=so
	PLATFORM=linux
endif

ifeq ($(shell uname), Darwin)
	SHLIB_EXT=dylib
	PLATFORM=osx
endif

ifeq ($($EXT_LLVM_DIR), "")
	EXT_LLVM_DIR=/usr/local/Cellar/extempore-llvm/3.4.1
endif

# Paths are relative to the libs directory
CORE_SRCS = core/std.xtm \
 core/math.xtm \
 core/audio_dsp.xtm \
 core/instruments.xtm \

EXT_SRCS = external/fft.xtm \
 external/sndfile.xtm \
 external/audio_dsp_ext.xtm \
 external/instruments_ext.xtm \
 external/glib.xtm \
 external/soil.xtm \
 external/opengl.xtm \
 external/shaders.xtm \
 external/assimp.xtm \
 external/rtmidi.xtm \
 external/openvg.xtm \

# user can override this to compile subset of files
SRCS = $(CORE_SRCS) $(EXT_SRCS)

EXTEMPORE = ./extempore
COMPILE_FLAGS = --nostd  --eval

CORE_STDLIB_SO = $(foreach F,$(CORE_SRCS:.xtm=.$(SHLIB_EXT)),libs/xtm$(notdir $F))
EXTERNAL_STDLIB_SO = $(foreach F,$(EXT_SRCS:.xtm=.$(SHLIB_EXT)),libs/xtm$(notdir $F))
ALL_SO = $(foreach F,$(SRCS:.xtm=.$(SHLIB_EXT)),libs/xtm$(notdir $F))

.PHONY: force-all clean clean-core clean-external pre-check

usage:
	@echo -e "Please Specify target:"
	@echo -e ""
	@echo -e " \033[0;32mall\033[0;00m            Compile both core and external stdlib components."
	@echo -e " \033[0;32mcore\033[0;00m           Compile core stdlib components only."
	@echo -e " \033[0;32mexternal\033[0;00m       Compile external stdlib components only."
	@echo -e " \033[0;32mforce-all\033[0;00m      Force recompilation of all components."
	@echo -e " \033[0;32mclean\033[0;00m          Clean all compiled stdlib components"
	@echo -e " \033[0;32mclean-core\033[0;00m     Clean core compiled stdlib components."
	@echo -e " \033[0;32mclean-external\033[0;00m Clean external compiled stdlib components."
	@echo -e ""
	@echo -e "To compile specific libraries only (paths are relative to 'libs/'):"
	@echo -e ""
	@echo -e ' make -f stdlib.make SRCS="external/sndfile.xtm core/std.xtm" all'
	@echo -e ""
	@echo -e "\033[0;33mNote\033[0;00m:"
	@echo -e ""
	@echo -e " Pre-compiling the stdlib will speed up load times but isn't necessary."
	@echo -e " Some componets may fail to compile if you do not have the necessary"
	@echo -e " libraries installed on your system. You may safely ignore these if you"
	@echo -e " do not require their functionality."
	@echo -e ""
	@echo -e " See the source files for instructions on installation."
	@echo -e ""

pre-check:
	@test -d "${EXT_LLVM_DIR}" || echo -e "\nYou need to set the \033[0;32mEXT_LLVM_DIR\033[0;00m environment variable to point to your (Extempore) LLVM directory.\n";
	@test -d "${EXT_LLVM_DIR}"

all: pre-check $(ALL_SO)
	@echo -e "\nDone compiling \033[0;32mall\033[0;00m.\n"

force-all: clean all

external: pre-check $(EXTERNAL_STDLIB_SO)
	@echo -e "\nDone compiling \033[0;32mexternal\033[0;00m.\n"

core: pre-check $(CORE_STDLIB_SO)
	@echo -e "\nDone compiling \033[0;32mcore\033[0;00m.\n"

clean:
	rm -f $(ALL_SO)

clean-core:
	rm -f $(CORE_STDLIB_SO)

clean-external:
	rm -f $(EXTERNAL_STDLIB_SO)

libs/xtm%.so: libs/core/%.xtm
	$(EXTEMPORE) $(COMPILE_FLAGS) "(sys:precomp:compile-xtm-file \"$?\" #t #t #t)"

libs/xtm%.so: libs/external/%.xtm
	$(EXTEMPORE) $(COMPILE_FLAGS) "(sys:precomp:compile-xtm-file \"$?\" #t #t #t)"

libs/xtm%.dynlib: libs/core/%.xtm
	$(EXTEMPORE) $(COMPILE_FLAGS) "(sys:precomp:compile-xtm-file \"$?\" #t #t #t)"

libs/xtm%.dynlib: libs/external/%.xtm
	$(EXTEMPORE) $(COMPILE_FLAGS) "(sys:precomp:compile-xtm-file \"$?\" #t #t #t)"
