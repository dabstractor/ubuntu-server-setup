#!/bin/bash

set -e

VM_NAME="test-server"

case "${1:-}" in
    start|launch)
        echo "Launching VM..."
        multipass launch --name "$VM_NAME" --cpus 2 --memory 2G --disk 10G
        echo "Setting password to 'password'..."
        multipass exec "$VM_NAME" -- bash -c "echo 'ubuntu:password' | sudo chpasswd"
        echo "Transferring files..."
        multipass transfer setup-server.sh "$VM_NAME:/home/ubuntu/"
        echo "✓ VM ready. Password is 'password'. Run: ./test.sh shell"
        ;;

    shell|ssh)
        # Check if VM exists, if not start it
        if ! multipass list | grep -q "$VM_NAME"; then
            echo "VM not found. Starting new VM..."
            "$0" start
        fi

        # Get VM IP for SSH with agent forwarding
        VM_IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')

        if [ -n "$VM_IP" ]; then
            echo "Connecting with SSH agent forwarding..."
            ssh -A ubuntu@"$VM_IP"
        else
            echo "Could not get VM IP, falling back to multipass shell..."
            multipass shell "$VM_NAME"
        fi
        ;;

    transfer|copy)
        echo "Transferring files..."
        multipass transfer setup-server.sh "$VM_NAME:/home/ubuntu/"
        echo "✓ Files transferred"
        ;;

    clean|destroy)
        echo "Destroying VM..."
        multipass delete "$VM_NAME"
        multipass purge
        echo "✓ VM destroyed"
        ;;

    restart)
        echo "Restarting VM..."
        multipass restart "$VM_NAME"
        echo "✓ VM restarted"
        ;;

    stop)
        multipass stop "$VM_NAME"
        echo "✓ VM stopped"
        ;;

    info)
        multipass info "$VM_NAME"
        ;;

    *)
        echo "Usage: $0 {start|shell|transfer|clean|restart|stop|info}"
        echo
        echo "Commands:"
        echo "  start     - Launch new VM and transfer files"
        echo "  shell     - Open shell in VM"
        echo "  transfer  - Copy files to existing VM"
        echo "  clean     - Destroy VM and purge"
        echo "  restart   - Restart VM"
        echo "  stop      - Stop VM"
        echo "  info      - Show VM info"
        exit 1
        ;;
esac
