#!/usr/bin/env bash
for secret in secrets/*.{yaml,yml,json}; do
    if [ -f "$secret" ]; then
        sops updatekeys "$secret"
    fi
done
