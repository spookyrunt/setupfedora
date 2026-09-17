#!/bin/bash
set -euo pipefail

RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest)"
NVIM_LATEST_TAG="$(jq -er '.tag_name' <<<"$RELEASE_JSON")"
CURRENT_VERSION="$(
  nvim --version 2>/dev/null |
    sed -n '1s/^NVIM //p' ||
    true
)"
if [[ "$CURRENT_VERSION" == "$NVIM_LATEST_TAG" ]]; then
  echo "Neovim is already installed and up to date ($CURRENT_VERSION). Skipping."
  exit 0
fi

echo "==> Installing latest stable Neovim..."
NVIM_URL="$(
  jq -er '
    .assets[]
    | select(.name == "nvim-linux-x86_64.tar.gz")
    | .browser_download_url
  ' <<<"$RELEASE_JSON"
)"
if [[ -z "$NVIM_URL" || "$NVIM_URL" == "null" ]]; then
  echo "Error: Failed to fetch the Neovim download URL."
  exit 1
fi

curl -LO "$NVIM_URL"
tar xzf nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo mv nvim-linux-x86_64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz
echo "Neovim $(nvim --version | head -1) installed"

echo "==> Registering nvim as system default editor..."
if ! grep -q "export EDITOR=/usr/local/bin/nvim" ~/.bash_profile 2>/dev/null; then
  printf '\nexport EDITOR=/usr/local/bin/nvim' >>~/.bash_profile
fi
if ! grep -q "export VISUAL=/usr/local/bin/nvim" ~/.bash_profile 2>/dev/null; then
  printf '\nexport VISUAL=/usr/local/bin/nvim' >>~/.bash_profile
fi
git config --global core.editor "nvim"
sudo git config --global core.editor "nvim"

echo "==> Installing LazyVim..."
# Back up existing config if present
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s)
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

echo "==> Writing nvim plugin configs..."
mkdir -p ~/.config/nvim/lua/plugins

cat >~/.config/nvim/lua/plugins/colorscheme.lua <<'EOF'
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-latte",
    },
  },
}
EOF

cat >~/.config/nvim/lua/plugins/korean.lua <<'EOF'
return {
  {
    "kiyoon/Korean-IME.nvim",
    keys = {
      {
        "<f12>",
        function() require("korean_ime").change_mode() end,
        mode = { "i", "n", "x", "s" },
        desc = "한/영",
      },
    },
    config = function()
      require("korean_ime").setup()
      vim.keymap.set("i", "<f9>", function()
        require("korean_ime").convert_hanja()
      end, { noremap = true, silent = true, desc = "한자" })
    end,
  },
}
EOF

cat >~/.config/nvim/lua/plugins/vimbegood.lua <<'EOF'
return {
  {
    "ThePrimeagen/vim-be-good",
    lazy = false,
  },
}
EOF

echo "==> Writing nvim configs..."
mkdir -p ~/.config/nvim/lua/config

cat >~/.config/nvim/lua/config/filetypefix.lua <<'EOF'
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local buf = args.buf
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" then return end
    -- Detect using the complete filename first.
    local filename = vim.fn.fnamemodify(path, ":t")
    local ft = vim.filetype.match({ filename = filename })
    if ft then
      vim.bo[buf].filetype = ft
      return
    end
    -- Treat the final dot-separated part as a temporary suffix.
    local original_name, suffix = filename:match("^(.*)%.([^./]+)$")
    if not original_name or not suffix or #suffix < 6 then return end
    -- Detect using only the restored filename.
    ft = vim.filetype.match({ filename = original_name })
    if ft then vim.bo[buf].filetype = ft end
  end,
})
EOF

if ! grep -Fqx 'require("config.filetypefix")' "~/.config/nvim/init.lua"; then
  printf '\nrequire("config.filetypefix")\n' >> "~/.config/nvim/init.lua"
fi

echo ""
echo "==> Finished installing LazyVim."
