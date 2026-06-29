#!/usr/bin/env node
'use strict';
const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const script = path.join(__dirname, '..', 'scripts', 'install.ps1');

if (!fs.existsSync(script)) {
  console.error('Cannot find install.ps1 at:', script);
  process.exit(1);
}

// Try pwsh (PowerShell 7+) first, fall back to powershell (Windows PowerShell 5.1)
const shells = process.platform === 'win32' ? ['pwsh', 'powershell'] : ['pwsh'];
const extraArgs = process.argv.slice(2); // forward any CLI args (e.g. --Force)

for (const shell of shells) {
  const result = spawnSync(
    shell,
    ['-ExecutionPolicy', 'Bypass', '-File', script, ...extraArgs],
    { stdio: 'inherit', shell: false }
  );
  if (result.error) continue; // shell not found, try next
  process.exit(result.status ?? 1);
}

console.error('PowerShell not found. Install it: https://github.com/PowerShell/PowerShell');
process.exit(1);
