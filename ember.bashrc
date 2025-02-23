############################
# Clean and reinstall node dependencies
############################
alias depclean="rm -rf node_modules && yarn install"


############################
# Various Proxy
############################
alias es="ember s -spr false --proxy https://localhost:5001"
alias esc="ember s -spr false --proxy https://localhost:6001"

clean() {
  # Display help
  if [[ $1 == "--help" ]]; then
    echo "Usage: clean [--include-lock] [--skip-install]"
    echo ""
    echo "  Removes all node_modules and lock files, then reinstalls dependencies."
    echo ""
    echo "  --include-lock  Removes the lock file as well."
    echo "  --skip-install  Skips the install step."
    return 0
  fi

  REGENERATE_LOCK_FILE=false
  SKIP_INSTALL=false

  for arg in "$@"; do
    if [[ $arg == "--include-lock" ]]; then
      REGENERATE_LOCK_FILE=true
    elif [[ $arg == "--skip-install" ]]; then
      SKIP_INSTALL=true
    fi
  done

  # Determine package manager
  if [[ -f "yarn.lock" ]]; then
    echo "Using yarn..."
    PACKAGE_MANAGER="yarn"
    LOCK_FILE="yarn.lock"
  elif [[ -f "package-lock.json" ]]; then
    echo "Using npm..."
    PACKAGE_MANAGER="npm"
    LOCK_FILE="package-lock.json"
  elif [[ -f "pnpm-lock.yaml" ]]; then
    echo "Using pnpm..."
    PACKAGE_MANAGER="pnpm"
    LOCK_FILE="pnpm-lock.yaml"
  else
    echo "Could not determine package manager, no lock file found."
    return 1
  fi

  # Remove lock file and node_modules
  echo "Removing dependencies..."
  DIRS=(`find ./ -maxdepth 3 -type d -name "node_modules" -prune`)
  if [[ ${#DIRS[@]} -gt 0 ]]; then
    echo "  Removing node_modules... (this may take a while)"
    for dir in "${DIRS[@]}"; do
      echo "    $dir"
      rm -rf "$dir"
    done
  else
    echo "  No node_modules found, skipping."
  fi

  if [[ $REGENERATE_LOCK_FILE == true ]]; then
    echo "  Removing lock file..."
    rm -rf "$LOCK_FILE"
  fi

  # Remove compiled files
  echo "Removing compiled files..."
  DIRS=(`find ./ -maxdepth 3 -type d -name "dist" -prune`)
  if [[ ${#DIRS[@]} -gt 0 ]]; then
    echo "  Removing dist..."
    for dir in "${DIRS[@]}"; do
      echo "    $dir"
      find "$dir" -not -name ".gitkeep" -a -not -wholename "$dir" -delete && \
        rmdir --ignore-fail-on-non-empty "$dir"
    done
  else
    echo "  No compiled files found, skipping."
  fi

  # Reinstall dependencies
  if [[ $SKIP_INSTALL == false ]]; then
    echo "Reinstalling dependencies... (this may take a while)"
    echo "  Installing dependencies via \`$PACKAGE_MANAGER install\`..."
    $PACKAGE_MANAGER install
  fi
}