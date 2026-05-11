#!/bin/bash
# Run from inside Public EC2

PRIVATE_IP="10.0.2.246"

echo "=== AWS Architecture Connectivity Tests ==="

echo -e "\n[1] Internet reachability (IGW):"
ping -c 3 8.8.8.8 && echo "✅ IGW OK" || echo "❌ IGW FAIL"

echo -e "\n[2] DNS Resolution:"
ping -c 3 google.com && echo "✅ DNS OK" || echo "❌ DNS FAIL"

echo -e "\n[3] Private EC2 reachability:"
ping -c 3 $PRIVATE_IP && echo "✅ Private EC2 OK" || echo "❌ Private EC2 FAIL"

echo -e "\n[4] Private EC2 SSH port:"
nc -zv $PRIVATE_IP 22 && echo "✅ SSH Port OK" || echo "❌ SSH Port FAIL"

echo -e "\n=== Tests Complete ==="
