import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

// Each check runs in its own Node process; the existing scripts explicitly exit.
for (const script of ['profile-rules.mjs', 'public-smoke.mjs', 'public-map-edge.mjs']) {
  const result = spawnSync(process.execPath, [fileURLToPath(new URL(script, import.meta.url))],
    {stdio:'inherit', timeout:120_000});
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
  console.log(`PASS: ${script}`);
}
