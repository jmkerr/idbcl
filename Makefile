SCFLAGS = -v -g -Onone
BIN = ./bin
NAME = idbcl
SRC = $(wildcard ./src/*.swift)

$(shell mkdir $(BIN))

all:
	swiftc \
		$(SCFLAGS) \
		$(SRC) \
		-o $(BIN)/$(NAME) \
		-framework iTunesLibrary,Foundation
	codesign \
		-s "-" \
		-v \
		$(BIN)/$(NAME)

clean:
	rm -r $(BIN)
