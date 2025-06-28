#!/bin/bash

set -e

INSTALL_DIR="$HOME/.shinibrowser"
SCRIPT_NAME="shinibrowser"
HISTORY_FILE="search_history.txt"
CONFIG_FILE="config.env"

echo "=== Shinibrowser Installation - Enhanced Version ==="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python3 to continue."
    exit 1
fi

# Check if pip is installed and try to install if missing
if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
    echo "📦 pip not found. Attempting to install..."
    
    # Try to install pip automatically based on the system
    if command -v apt &> /dev/null; then
        echo "🔧 Detected Debian/Ubuntu system. Installing pip..."
        sudo apt update && sudo apt install -y python3-pip
    elif command -v dnf &> /dev/null; then
        echo "🔧 Detected Fedora system. Installing pip..."
        sudo dnf install -y python3-pip
    elif command -v yum &> /dev/null; then
        echo "🔧 Detected CentOS/RHEL system. Installing pip..."
        sudo yum install -y python3-pip
    elif command -v pacman &> /dev/null; then
        echo "🔧 Detected Arch Linux system. Installing pip..."
        sudo pacman -S --noconfirm python-pip
    elif command -v brew &> /dev/null; then
        echo "🔧 Detected macOS with Homebrew. Installing pip..."
        brew install python
    else
        echo "❌ Cannot auto-install pip. Please install it manually:"
        echo "   • Ubuntu/Debian: sudo apt install python3-pip"
        echo "   • Fedora: sudo dnf install python3-pip"
        echo "   • CentOS/RHEL: sudo yum install python3-pip"
        echo "   • Arch: sudo pacman -S python-pip"
        echo "   • macOS: brew install python"
        exit 1
    fi
    
    # Check again after installation
    if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
        echo "❌ pip installation failed. Please install manually."
        exit 1
    fi
fi

# Ask for API key
echo "🔑 OpenAI API Key Configuration"
echo "💡 Tip: You can paste your API key even if you don't see it being typed"
echo -n "Enter your OpenAI API key (sk-xxxxx): "
read OPENAI_API_KEY_INPUT
if [[ -z "$OPENAI_API_KEY_INPUT" ]]; then
  echo "❌ API key cannot be empty."
  exit 1
fi

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Create configuration file (safer than shell profile)
cat > "$INSTALL_DIR/$CONFIG_FILE" << EOF
OPENAI_API_KEY=$OPENAI_API_KEY_INPUT
EOF
chmod 600 "$INSTALL_DIR/$CONFIG_FILE"  # Only owner can read

# Create history file if it doesn't exist
touch "$INSTALL_DIR/$HISTORY_FILE"

echo "📦 Installing Python dependencies..."

# Try different pip commands in order of preference
if command -v pip3 &> /dev/null; then
    pip3 install --user openai duckduckgo-search rich requests beautifulsoup4 wikipedia || {
        echo "❌ Error installing dependencies. Please check your internet connection."
        exit 1
    }
elif python3 -m pip --version &> /dev/null; then
    python3 -m pip install --user openai duckduckgo-search rich requests beautifulsoup4 wikipedia || {
        echo "❌ Error installing dependencies. Please check your internet connection."
        exit 1
    }
else
    echo "❌ No working pip installation found."
    exit 1
fi

# Write improved shinibrowser script with multiple search APIs
cat > "$INSTALL_DIR/$SCRIPT_NAME" << 'EOF'
#!/usr/bin/env python3

import sys
import os
import json
import time
import urllib.parse
import random
from datetime import datetime
from pathlib import Path
import requests
from bs4 import BeautifulSoup
import wikipedia
from rich.console import Console
from rich.panel import Panel
from rich.markdown import Markdown

# Initialize Rich console
console = Console()

# ========================
# CONFIGURATION PARAMETERS
# ========================
MAX_RESULTS_TO_FETCH = 5
MAX_RESULTS_TO_SHOW = 3
HISTORY_FILE = "search_history.txt"
CONFIG_FILE = "config.env"
SCRIPT_DIR = Path(__file__).parent

# Search engine configurations with priorities
SEARCH_ENGINES = [
    {
        'name': 'DuckDuckGo',
        'function': 'search_duckduckgo',
        'priority': 1,
        'enabled': True,
        'rate_limit_delay': 2
    },
    {
        'name': 'Searx (Public Instance)',
        'function': 'search_searx',
        'priority': 2,
        'enabled': True,
        'rate_limit_delay': 1
    },
    {
        'name': 'Google (Scraping)',
        'function': 'search_google_scraping',
        'priority': 3,
        'enabled': True,
        'rate_limit_delay': 3
    },
    {
        'name': 'Bing (Scraping)',
        'function': 'search_bing_scraping',
        'priority': 4,
        'enabled': True,
        'rate_limit_delay': 2
    },
    {
        'name': 'Wikipedia',
        'function': 'search_wikipedia',
        'priority': 5,
        'enabled': True,
        'rate_limit_delay': 1
    }
]

def load_config():
    """Load configuration from config.env file"""
    config_path = SCRIPT_DIR / CONFIG_FILE
    if not config_path.exists():
        console.print("❌ Configuration file not found.", style="red")
        console.print("Please run the installation script again.", style="yellow")
        sys.exit(1)
    
    config = {}
    with open(config_path, 'r') as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                config[key] = value
    return config

def get_random_headers():
    """Get random user agent headers to avoid blocking"""
    user_agents = [
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:89.0) Gecko/20100101 Firefox/89.0'
    ]
    return {
        'User-Agent': random.choice(user_agents),
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
    }

def search_duckduckgo(query, max_results=MAX_RESULTS_TO_FETCH):
    """Search DuckDuckGo with error handling"""
    try:
        from duckduckgo_search import DDGS
        with DDGS() as ddgs:
            results = list(ddgs.text(query, max_results=max_results))
        return results
    except Exception as e:
        console.print(f"⚠️  DuckDuckGo error: {str(e)}", style="yellow")
        return None

def search_searx(query, max_results=MAX_RESULTS_TO_FETCH):
    """Search using Searx public instances"""
    searx_instances = [
        'https://searx.be',
        'https://searx.info',
        'https://searx.prvcy.eu',
        'https://search.sapti.me'
    ]
    
    for instance in searx_instances:
        try:
            params = {
                'q': query,
                'format': 'json',
                'categories': 'general'
            }
            
            response = requests.get(
                f"{instance}/search",
                params=params,
                headers=get_random_headers(),
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                results = []
                for item in data.get('results', [])[:max_results]:
                    results.append({
                        'title': item.get('title', 'No title'),
                        'body': item.get('content', 'No description'),
                        'href': item.get('url', '')
                    })
                return results
                
        except Exception as e:
            continue
    
    console.print("⚠️  All Searx instances failed", style="yellow")
    return None

def search_google_scraping(query, max_results=MAX_RESULTS_TO_FETCH):
    """Search Google by scraping (use with caution)"""
    try:
        encoded_query = urllib.parse.quote_plus(query)
        url = f"https://www.google.com/search?q={encoded_query}&num={max_results}"
        
        headers = get_random_headers()
        response = requests.get(url, headers=headers, timeout=10)
        
        if response.status_code != 200:
            return None
            
        soup = BeautifulSoup(response.content, 'html.parser')
        results = []
        
        # Parse Google search results
        for g in soup.find_all('div', class_='g')[:max_results]:
            title_elem = g.find('h3')
            link_elem = g.find('a')
            desc_elem = g.find('span', {'data-dobid': 'dfn'}) or g.find('div', class_='VwiC3b')
            
            if title_elem and link_elem:
                title = title_elem.get_text()
                link = link_elem.get('href', '')
                desc = desc_elem.get_text() if desc_elem else 'No description'
                
                # Clean up Google's redirect URLs
                if link.startswith('/url?q='):
                    link = urllib.parse.unquote(link.split('/url?q=')[1].split('&')[0])
                
                results.append({
                    'title': title,
                    'body': desc,
                    'href': link
                })
        
        return results if results else None
        
    except Exception as e:
        console.print(f"⚠️  Google scraping error: {str(e)}", style="yellow")
        return None

def search_bing_scraping(query, max_results=MAX_RESULTS_TO_FETCH):
    """Search Bing by scraping"""
    try:
        encoded_query = urllib.parse.quote_plus(query)
        url = f"https://www.bing.com/search?q={encoded_query}&count={max_results}"
        
        headers = get_random_headers()
        response = requests.get(url, headers=headers, timeout=10)
        
        if response.status_code != 200:
            return None
            
        soup = BeautifulSoup(response.content, 'html.parser')
        results = []
        
        # Parse Bing search results
        for result in soup.find_all('li', class_='b_algo')[:max_results]:
            title_elem = result.find('h2')
            link_elem = result.find('a')
            desc_elem = result.find('p') or result.find('div', class_='b_caption')
            
            if title_elem and link_elem:
                title = title_elem.get_text()
                link = link_elem.get('href', '')
                desc = desc_elem.get_text() if desc_elem else 'No description'
                
                results.append({
                    'title': title,
                    'body': desc,
                    'href': link
                })
        
        return results if results else None
        
    except Exception as e:
        console.print(f"⚠️  Bing scraping error: {str(e)}", style="yellow")
        return None

def search_wikipedia(query, max_results=MAX_RESULTS_TO_FETCH):
    """Search Wikipedia as fallback"""
    try:
        wikipedia.set_lang("en")
        search_results = wikipedia.search(query, results=max_results)
        
        results = []
        for title in search_results[:max_results]:
            try:
                page = wikipedia.page(title)
                summary = wikipedia.summary(title, sentences=2)
                
                results.append({
                    'title': page.title,
                    'body': summary,
                    'href': page.url
                })
            except wikipedia.exceptions.DisambiguationError as e:
                # Try the first option from disambiguation
                try:
                    page = wikipedia.page(e.options[0])
                    summary = wikipedia.summary(e.options[0], sentences=2)
                    results.append({
                        'title': page.title,
                        'body': summary,
                        'href': page.url
                    })
                except:
                    continue
            except:
                continue
        
        return results if results else None
        
    except Exception as e:
        console.print(f"⚠️  Wikipedia error: {str(e)}", style="yellow")
        return None

def search_with_fallback(query, max_results=MAX_RESULTS_TO_FETCH):
    """Search using multiple engines with fallback logic"""
    # Sort search engines by priority
    sorted_engines = sorted([e for e in SEARCH_ENGINES if e['enabled']], 
                          key=lambda x: x['priority'])
    
    for engine in sorted_engines:
        console.print(f"🔍 Trying {engine['name']}...", style="blue")
        
        try:
            search_func = globals()[engine['function']]
            results = search_func(query, max_results)
            
            if results and len(results) > 0:
                console.print(f"✅ {engine['name']} returned {len(results)} results", style="green")
                return results, engine['name']
            else:
                console.print(f"⚠️  {engine['name']} returned no results", style="yellow")
                
        except Exception as e:
            console.print(f"❌ {engine['name']} failed: {str(e)}", style="red")
        
        # Add delay to avoid rate limiting
        if engine['rate_limit_delay'] > 0:
            time.sleep(engine['rate_limit_delay'])
    
    return None, None

def query_openai(prompt, api_key, max_retries=5):
    """Query OpenAI with retry and error handling"""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": "deepseek-r1-distill-llama-70b",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.3,
        "max_tokens": 1000
    }
    
    for attempt in range(max_retries):
        try:
            response = requests.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers=headers,
                json=data,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()['choices'][0]['message']['content']
            elif response.status_code == 429:
                wait_time = min(60, 2 ** attempt)
                console.print(f"⏳ Rate limit reached. Waiting {wait_time}s... (attempt {attempt + 1}/{max_retries})", style="yellow")
                time.sleep(wait_time)
                continue
            else:
                console.print(f"❌ OpenAI API error: {response.status_code}", style="red")
                return None
                
        except requests.exceptions.Timeout:
            console.print("⏳ Request timeout. Retrying...", style="yellow")
        except Exception as e:
            console.print(f"❌ Unexpected error: {str(e)}", style="red")
            return None
    
    console.print("❌ Unable to complete request after multiple attempts.", style="red")
    return None

def save_to_history(query, engine_used=None):
    """Save query to history with engine information"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    engine_info = f" (via {engine_used})" if engine_used else ""
    history_path = SCRIPT_DIR / HISTORY_FILE
    try:
        with open(history_path, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {query}{engine_info}\n")
    except Exception as e:
        console.print(f"⚠️  Unable to save to history: {e}", style="yellow")

def main():
    # Check arguments
    if len(sys.argv) < 2:
        console.print(Panel(
            "[bold]Usage:[/bold] shinibrowser \"your question here\"\n\n"
            "[dim]Examples:[/dim]\n"
            "• shinibrowser \"latest tech news\"\n"
            "• shinibrowser \"weather forecast Milan\"\n\n"
            "[bold]Features:[/bold]\n"
            "• Multiple search engines with automatic fallback\n"
            "• DuckDuckGo → Searx → Google → Bing → Wikipedia\n"
            "• Intelligent rate limiting and error handling",
            title="❓ How to use Shinibrowser Enhanced"
        ))
        sys.exit(1)

    query = " ".join(sys.argv[1:])
    
    # Load configuration
    config = load_config()
    api_key = config.get('OPENAI_API_KEY')
    
    if not api_key:
        console.print("❌ OpenAI API key not found in configuration.", style="red")
        sys.exit(1)

    # Show query
    console.print(Panel(f"🔍 [bold]{query}[/bold]", title="Searching with Multi-Engine Fallback..."))
    
    # Search with fallback
    with console.status("🔍 Searching across multiple sources..."):
        results, engine_used = search_with_fallback(query)
    
    if not results:
        console.print("❌ No results found from any search engine.", style="red")
        sys.exit(0)
    
    # Save query to history with engine info
    save_to_history(query, engine_used)
    
    console.print(f"✅ Found {len(results)} sources using {engine_used}", style="green")
    
    # Build prompt for GPT
    sources_text = "\n\n".join([
        f"[SOURCE {i+1}] {r['title']}\n{r['body']}\nURL: {r['href']}"
        for i, r in enumerate(results)
    ])
    
    prompt = f"""You are an expert research assistant. Analyze the provided sources and answer the question accurately and comprehensively.

INSTRUCTIONS:
- Answer in English
- Use only information from the provided sources
- If sources don't contain sufficient information, state this clearly
- Cite sources using [1], [2], etc.
- Organize the response clearly and readably

QUESTION: "{query}"

SOURCES:
{sources_text}

ANSWER:"""
    
    # Query OpenAI
    with console.status("🤖 Processing response with AI..."):
        answer = query_openai(prompt, api_key)
    
    if not answer:
        console.print("❌ Unable to get response from AI.", style="red")
        sys.exit(1)
    
    # Output response
    console.print("\n")
    console.print(Panel(
        Markdown(answer),
        title=f"🎯 Answer (powered by {engine_used})",
        border_style="green"
    ))
    
    # Show sources
    console.print(f"\n📚 [bold]Sources consulted (top {min(MAX_RESULTS_TO_SHOW, len(results))} of {len(results)}) via {engine_used}:[/bold]\n")
    
    for i, r in enumerate(results[:MAX_RESULTS_TO_SHOW]):
        console.print(f"[dim][{i+1}][/dim] {r['title']}")
        console.print(f"    [link]{r['href']}[/link]\n")

if __name__ == "__main__":
    main()
EOF

# Make script executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Detect shell and add only PATH (not API key)
PROFILE_FILE=""
if [ -n "$ZSH_VERSION" ]; then
    PROFILE_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    PROFILE_FILE="$HOME/.bashrc"
else
    PROFILE_FILE="$HOME/.bashrc"
fi

# Check if PATH is already configured
if grep -q "export PATH=\"$INSTALL_DIR:\$PATH\"" "$PROFILE_FILE" 2>/dev/null; then
    echo "✅ PATH already configured in $PROFILE_FILE"
else
    echo "" >> "$PROFILE_FILE"
    echo "# Shinibrowser - added automatically" >> "$PROFILE_FILE"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$PROFILE_FILE"
    echo "✅ PATH added to $PROFILE_FILE"
fi

# Create useful alias to view history
if ! grep -q "alias shini-history" "$PROFILE_FILE" 2>/dev/null; then
    echo "alias shini-history='tail -20 $INSTALL_DIR/$HISTORY_FILE'" >> "$PROFILE_FILE"
fi

echo ""
echo "🎉 === Installation Complete - Enhanced Version! ==="
echo ""
echo "🚀 NEW FEATURES:"
echo "   • Multi-engine fallback system"
echo "   • DuckDuckGo → Searx → Google → Bing → Wikipedia"
echo "   • Intelligent rate limiting and error handling"
echo "   • Random user agents to avoid blocking"
echo "   • Detailed search engine reporting"
echo ""
echo "📋 To get started:"
echo "   1. Open a new terminal or run: source $PROFILE_FILE"
echo "   2. Use: shinibrowser \"your question\""
echo ""
echo "🔧 Useful commands:"
echo "   • shini-history  → show last 20 searches (with engine info)"
echo "   • ls $INSTALL_DIR → view configuration files"
echo ""
echo "🔒 Your API key is securely saved in: $INSTALL_DIR/$CONFIG_FILE"
echo ""
echo "🎯 Search Engine Priority Order:"
echo "   1. DuckDuckGo (fastest, primary)"
echo "   2. Searx Public Instances (privacy-focused)"
echo "   3. Google Scraping (comprehensive results)"
echo "   4. Bing Scraping (alternative perspective)"
echo "   5. Wikipedia (reliable fallback)"
echo ""
echo "Happy searching with enhanced reliability! 🚀"