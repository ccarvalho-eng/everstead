#!/bin/bash

# Everstead Documentation Generator
# This script generates and opens the project documentation

echo "📚 Generating Everstead documentation..."

# Generate documentation
mix docs

if [ $? -eq 0 ]; then
    echo "✅ Documentation generated successfully!"
    echo "📖 Opening documentation in your browser..."
    
    # Open documentation in browser
    if command -v open &> /dev/null; then
        open doc/index.html
    elif command -v xdg-open &> /dev/null; then
        xdg-open doc/index.html
    else
        echo "🌐 Documentation available at: doc/index.html"
    fi
else
    echo "❌ Failed to generate documentation"
    exit 1
fi