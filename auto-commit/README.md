# Auto commit and generate messages

The `profile` file contains custom Git wrapper functions that integrate with OpenAI's GPT-4 and Anthropic's Claude to automatically generate commit messages from staged changes. Key features include:

- `git ac`: Adds all files and commits with Claude-generated message
- `git ach`: Adds all files and commits with ChatGPT-generated message  
- `git cm`: Direct commit with AI-generated message
- `git pusho`: Status check and push to origin
- `git revert`: Soft reset to previous commit


Remember to save it as `.profile` add it to your bashrc or bash_profile with:

´´´source ~/.profile´´´

*You will need the api keys as well: **OPENAI_API_KEY** or **ANTHROPIC_API_KEY**