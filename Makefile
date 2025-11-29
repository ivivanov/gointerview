.PHONY: serve build clean new help

# Default target
help:
	@echo "Available commands:"
	@echo "  make serve    - Start Hugo development server with live reload"
	@echo "  make build    - Build the site for production"
	@echo "  make clean    - Remove generated files"
	@echo "  make new      - Create new content (usage: make new POST=path/filename.md)"
	@echo "  make drafts   - Serve including draft content"

# Start development server
serve:
	hugo server --buildDrafts --watch

# Start server including drafts
drafts:
	hugo server --buildDrafts --buildFuture --watch

# Build for production
build:
	hugo --minify

# Clean generated files
clean:
	rm -rf public/
	rm -rf resources/_gen/

# Create new content
new:
ifndef POST
	@echo "Usage: make new POST=path/filename.md"
	@echo "Example: make new POST=concurrency/new-topic.md"
else
	hugo new content/$(POST)
endif

