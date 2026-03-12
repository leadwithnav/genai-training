/**
 * scripts/lint.js
 *
 * Zero-dependency syntax checker.
 * Walks tests/, pages/, and src/ and runs `node --check` on every .js file.
 * Exits with code 1 if any file fails so the CI step is marked red.
 *
 * Usage: node scripts/lint.js
 */

const { execSync } = require('child_process');
const fs   = require('fs');
const path = require('path');

/**
 * Recursively collects all .js files under `dir`.
 * Returns an empty array if the directory does not exist.
 * @param {string} dir
 * @returns {string[]}
 */
function collectJsFiles(dir) {
    const results = [];
    if (!fs.existsSync(dir)) return results;

    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            results.push(...collectJsFiles(full));
        } else if (entry.name.endsWith('.js')) {
            results.push(full);
        }
    }
    return results;
}

// Directories to scan (relative to the playwright/ folder)
const dirsToScan = ['tests', 'pages', 'src'];
const files      = dirsToScan.flatMap(collectJsFiles);

if (files.length === 0) {
    console.log('No .js files found to check.');
    process.exit(0);
}

let failed = false;

for (const file of files) {
    try {
        execSync(`node --check "${file}"`, { stdio: 'pipe' });
        console.log(`✓  ${file}`);
    } catch (err) {
        console.error(`✗  ${file}`);
        // stderr contains the actual syntax error from Node
        const stderr = err.stderr?.toString().trim();
        if (stderr) console.error(`   ${stderr}`);
        failed = true;
    }
}

console.log('');
if (failed) {
    console.error(`Syntax check FAILED — fix the error(s) shown above.`);
    process.exit(1);
}
console.log(`All ${files.length} file(s) passed syntax check.`);
