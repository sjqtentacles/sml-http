# sml-http build
MLTON      ?= mlton
BIN        := bin
LIBDIR     := lib/github.com/sjqtentacles/sml-http
VENDOR     := lib/github.com/sjqtentacles/sml-uri
TEST_MLB   := test/sources.mlb
CLI_MLB    := bin/http.mlb
SRCS       := $(wildcard $(LIBDIR)/*.sml $(LIBDIR)/*.sig $(VENDOR)/*.sml $(VENDOR)/*.sig) \
              $(wildcard test/*.sml) $(TEST_MLB) $(LIBDIR)/sources.mlb $(VENDOR)/sources.mlb

.PHONY: all test poly test-poly all-tests cli example clean

all: $(BIN)/test-mlton

$(BIN)/test-mlton: $(SRCS) | $(BIN)
	$(MLTON) -output $@ $(TEST_MLB)

test: $(BIN)/test-mlton
	$(BIN)/test-mlton

poly: $(BIN)/test-poly

$(BIN)/test-poly: $(SRCS) tools/polybuild | $(BIN)
	sh tools/polybuild -o $@ $(TEST_MLB)

test-poly: $(BIN)/test-poly
	$(BIN)/test-poly

all-tests: test test-poly

example: $(BIN)/demo
	./$(BIN)/demo

$(BIN)/demo: $(SRCS) examples/demo.sml examples/sources.mlb | $(BIN)
	$(MLTON) -output $@ examples/sources.mlb

cli: $(BIN)/http

$(BIN)/http: $(SRCS) bin/http.sml $(CLI_MLB) | $(BIN)
	$(MLTON) -output $@ $(CLI_MLB)

$(BIN):
	mkdir -p $(BIN)

clean:
	rm -f $(BIN)/test-mlton $(BIN)/test-poly $(BIN)/http
	rm -f *.o
