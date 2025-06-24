#!/bin/bash
set -e

echo "[1/2] Starting Windows VM (winvm)..."
vagrant up winvm

echo "[2/2] Starting Ubuntu VM (ubuntu)..."
vagrant up ubuntu --provider=libvirt
