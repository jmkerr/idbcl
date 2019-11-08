BIN = ./bin
NAME = idbcl
SRC = $(wildcard Sources/$(NAME)/*.swift)

LIBNAME = libIdbcl
LIBPATH = $(BIN)/$(LIBNAME).dylib
MODULEPATH = $(BIN)/$(LIBNAME).swiftmodule
LIBSRC = $(wildcard Sources/$(LIBNAME)/*.swift)

.PHONY: idbcl
idbcl: libIdbcl
	$(shell mkdir -p $(BIN))
	swiftc \
		-o $(BIN)/$(NAME) \
		-I$(BIN) \
		$(LIBPATH) \
		$(SRC)
	install_name_tool \
		-change $(LIBPATH) \
		@executable_path/$(LIBNAME).dylib \
		$(BIN)/$(NAME)
	codesign \
		--sign "-" -v \
		$(BIN)/$(NAME)

.PHONY: libIdbcl
libIdbcl:
	$(shell mkdir -p $(BIN))
	swiftc \
		-framework iTunesLibrary \
		-emit-library \
		-o $(LIBPATH) \
		-emit-module \
		-emit-module-path $(MODULEPATH) \
		-module-name $(LIBNAME) \
		$(LIBSRC) 

.PHONY: clean
clean:
	rm -r $(BIN)

