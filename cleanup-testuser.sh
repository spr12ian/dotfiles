#!/bin/bash
set -euo pipefail

TEST_USER="testuser"

echo "Stopping all processes for $TEST_USER..."

# Wait a moment for processes to fully exit
sleep 3

if pkill -u $TEST_USER; then
    echo "Processes killed."
else
    echo "No processes to kill or pkill not needed."
fi

# Wait a moment for processes to fully exit
sleep 3

echo "Deleting user $TEST_USER..."
sudo userdel -r $TEST_USER || echo "User $TEST_USER does not exist."

echo "Checking for stray files..."
sudo find / -user $TEST_USER -print 2>/dev/null || echo "No stray files found."

echo "Checking for group $TEST_USER..."
if getent group $TEST_USER >/dev/null; then
    echo "Deleting group $TEST_USER..."
    sudo groupdel $TEST_USER
else
    echo "Group $TEST_USER not found."
fi

sudo rm -f /tmp/${TEST_USER}_*

echo "Cleanup complete."
