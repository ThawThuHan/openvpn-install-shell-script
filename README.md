# OpenVPN Install Shell Script

This repository provides a simple and automated way to install and configure an OpenVPN server on your Linux machine using a shell script. The script will handle the installation of OpenVPN, configuration, and generation of client certificates.

## Features

- Automated OpenVPN server installation.
- Easy configuration with default and customizable settings.
- Generates client certificates and configuration files.
- Supports multiple Linux distributions.

## Prerequisites

- A Linux-based operating system (Ubuntu, Debian, CentOS, Rocky Linux, etc.).
- Root or sudo access to the server.

## Installation

1. **Clone the repository:**

   ```sh
   git clone https://github.com/ThawThuHan/openvpn-install-shell-script.git
   cd openvpn-install-shell-script
   ```

2. **Make the script executable:**

   ```sh
   sudo chmod +x openvpn-install.sh
   sudo chmod +x generate-openvpn-users.sh
   ```

3. **Run the script:**

   ```sh
   ./openvpn-install.sh
   ```
   
4. **Check the OpenVPN service:***
   ```sh
   sudo systemctl status openvpn@server
   ```
   or
   ```sh
   sudo systemctl status openvpn-server@server
   ```

## Generating ovpn file for OpenVPN Client

1. **Run the script:**
   ./generate-openvpn-users.sh \<name\>
   ```sh
   ./generate-openvpn-users.sh user1
   ```
2. **Copy the ovpn file to your local host:**
   ```sh
   scp <username>@<IP or server name>:~/user1 .
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue to help improve this project.

