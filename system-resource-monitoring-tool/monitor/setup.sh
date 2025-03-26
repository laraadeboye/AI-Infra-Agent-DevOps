#!/usr/bin/env bash

set -e  # Exit on any error

if [ "$EUID" -ne 0 ]; then
   echo "This script must be run as root (e.g., sudo ./setup.sh)" 
   exit 1
fi

LOG_FILE="/var/log/monitor_setup/setup.log"


# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
    logger -t monitor_setup "$1"
}

# Function to check if a package is installed
is_package_installed() {
    dpkg -s "$1" &> /dev/null
}

# Function to check if a Python package is installed
is_python_package_installed() {
    pip3 show"import $1" &> /dev/null 
}

# Function to install system packages 
install_packages () {    
    log "Updating package lists..."
    sudo apt update -y
    
    PACKAGES=("python3" "python3-pip" "sqlite3")
    for package in "${PACKAGES[@]}"; do
        if is_package_installed "$package"; then
            log "$package is already installed."                       
        else                       
            log "Installing $package..."
            sudo apt install "$package" -y
            log "$package installed successfully."
        fi
    done

}



# Function to Install Python libraries
install_python_libraries() {    
    log "Installing python libraries"

    PYTHON_PACKAGES=("psutil" "matplotlib" "slack_sdk")
    for package in "${PYTHON_PACKAGES[@]}"; do
        if  is_python_package_installed "$package"; then
            log "Python package $package is already installed"                       
        else
            log "Installing Python package: $package..."
            if ! python3 -m pip install "$package"; then
                log "Failed to install critical Python package: $package"
                exit 1
            else
                log "Python package $package installed successfully."
            fi            
            
        fi
    done
}

# Function to create necessary directories
create_directories() {
    DIRECTORIES=("/var/log/monitor_setup" $HOME/monitor/graphs $HOME/monitor/logs)
    for directory in "${DIRECTORIES[@]}"; do
        if [ ! -d "$directory" ]; then            
            log "Creating directory: $directory..."
            sudo mkdir -p "$directory"
            sudo chown "$USER:$USER" "$directory"
        else
            log "Directory $directory already exists."            
        fi
    done
    sudo touch "$LOG_FILE"
    sudo chown "$USER:$USER" "$LOG_FILE"
  
}

# Main execution
log "Starting system setup..."
echo "Starting system setup..."
create_directories
install_packages
install_python_libraries


# # Run the monitoring tool

# MONITOR_SCRIPT="$HOME/monitor/monitor.py"
# if [ -f "$MONITOR_SCRIPT" ]; then    
#     echo "Running the monitoring tool..."
#     python3 "$MONITOR_SCRIPT"
# else
#     log "Error: Monitoring script not found at $MONITOR_SCRIPT. Kindly create the python script first."
#     echo "Error: Monitoring script not found at $MONITOR_SCRIPT." 
#     exit 1
# fi
