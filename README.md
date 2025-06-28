# 🔍 Shinibrowser - Terminal Web AI Search Engine

Shinibrowser is an interactive AI search engine for the terminal, designed for those who live in the CLI but don't want to give up artificial intelligence and the power of the web.

It combines intelligent scraping, distributed search engines, and AI assistant in a single command-line interface — all this with automatic fallback and search history tracking.

Simple to use, powerful as a browser... but ninja. 🥷

---

## ⚙️ Main Features

- ✅ 100% terminal interface
- 🔄 Multi-engine with intelligent fallback:
  - DuckDuckGo → Searx → Google → Bing → Wikipedia
- 🧠 Integrated AI (Groq/OpenAI compatible)
- 📚 Consulted sources included
- 🗂 Persistent search history
- 🎨 Readable and formatted output with rich
- 🔐 API key stored locally and securely


---

## 🧪 Usage Examples

```bash
shinibrowser "Who was Napoleon?"
```

Output:
```
🎯 Answer (powered by DuckDuckGo)
Napoleon Bonaparte was a French military and political leader who rose to prominence during the French Revolution. He became Emperor of the French and led several successful campaigns during the Napoleonic Wars...

📚 Sources consulted (top 3 of 5) via DuckDuckGo:
[1] Napoleon - Wikipedia
[2] History.com - Napoleon Biography
[3] Britannica.com - Napoleon Bonaparte
```

View your recent query history:
```bash
shini-history
```

---

## 🚀 Installation

Open a terminal and run:
```bash
bash <(curl -s https://raw.githubusercontent.com/yourusername/shinibrowser/main/install.sh)
```

Or clone the repo manually:
```bash
git clone https://github.com/yourusername/shinibrowser.git
cd shinibrowser
chmod +x install.sh
./install.sh
```

During installation, you'll be asked to paste your API Key.

---

## 🔐 Where do I find my API Key?

Shinibrowser uses Groq (OpenAI-compatible APIs).

Go to [https://console.groq.com/keys](https://console.groq.com/keys)

Click "Create API key", copy the key, and paste it when prompted by the script.

> Already have an OpenAI key? You can use it by modifying the backend in the script.

Your key is saved in:
```
$HOME/.shinibrowser/config.env
```

---

## 🧽 Uninstallation

Want to remove everything?
```bash
bash uninstall.sh
```

Or delete manually:
```bash
rm -rf $HOME/.shinibrowser
sed -i '/shinibrowser/d' ~/.bashrc ~/.zshrc
```

---

## 🧠 Powered by

- Python 3
- rich
- duckduckgo_search
- requests + BeautifulSoup
- wikipedia
- Groq (or OpenAI compatible)

---

## 📁 Structure

| File/Directory         | Description                           |
|------------------------|---------------------------------------|
| ~/.shinibrowser/       | Main script directory                 |
| shinibrowser           | The Python binary                     |
| config.env             | Contains your API key                 |
| search_history.txt     | Search history                        |


---

## 👨‍💻 Author

Created with passion by [Shinigami](https://github.com/yourusername) 🧠⚔️

With dark and loving assistance from Claude 🤖

---

## 🛠️ Technical Details

### Search Engine Priority Order
1. **DuckDuckGo** (fastest, primary)
2. **Searx Public Instances** (privacy-focused)
3. **Google Scraping** (comprehensive results)
4. **Bing Scraping** (alternative perspective)
5. **Wikipedia** (reliable fallback)

### Anti-Blocking Features
- Random user agents to appear as normal browsers
- Intelligent delays between requests (1-3 seconds)
- Realistic headers to avoid detection
- Automatic rotation of Searx instances

### Error Handling
- If one engine fails → automatically moves to the next
- Detailed logging of which engine provided results
- History saving with engine info

---

## 🔧 Configuration

The script automatically handles configuration, but you can manually edit:

```bash
nano ~/.shinibrowser/config.env
```

To change the AI model, edit the script and modify:
```python
"model": "deepseek-r1-distill-llama-70b"
```

---

## 📊 Command Reference

| Command | Description |
|---------|-------------|
| `shinibrowser "query"` | Perform a search |
| `shini-history` | View last 20 searches |
| `ls ~/.shinibrowser/` | View configuration files |

---

## 🚨 Troubleshooting

### "Command not found"
```bash
source ~/.bashrc  # or ~/.zshrc
hash -r
```

### API Rate Limits
The script automatically handles rate limits with exponential backoff and engine fallback.

### No Results
If all search engines fail, try:
- Check your internet connection
- Wait a few minutes and retry
- Verify your API key is valid

---

## 🤝 Contributing

Found a bug? Want to add a feature? 

1. Fork the repository
2. Create your feature branch
3. Submit a pull request

### Ideas for contributions:
- Additional search engines
- Better scraping resistance
- More AI model support
- Enhanced output formatting

---

## 📜 License

This project is open source. Use it, modify it, share it!

---

## 🙏 Acknowledgments

- Thanks to the open source community
- Groq for fast AI inference
- All the search engines we respectfully scrape
- Terminal lovers everywhere 🖥️❤️
