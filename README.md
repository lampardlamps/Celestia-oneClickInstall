# One click installation of Celestia light nodes
(Tested on google cloud ubuntu version 20.04)

This is a script that installs all the necessary components to start a light node on the Celestia network, and sets up the systemd configuration. It can be easily adapted for all other node types and networks within the Celestia family.

To use the script, follow the steps below:

1. Open a terminal window and navigate to the directory where you want to save the script.

2. save the bash script.

3. Define the node version and network by setting the values for the VER and NETWORK variables in the script.

4. Run the script by typing the following command and pressing Enter:
```
bash oneClick.sh
```

5. If you would like to start executing the script from a specific line, type "y" when prompted and enter the line number you want to start from.

6. The script will install the necessary dependencies, including Go, and will check the Go version.

7. After installing the dependencies, the script will install the Celestia node and check its version.

8. The script will prompt you to generate a new key or enter the name of an existing key to use.

9. Finally, the script will initiate the light node client and configure the systemD for the light node.

Note: Before running the script, ensure that you have the necessary permissions to install software and create systemD services.

Good luck and happy Celestia node setup!
