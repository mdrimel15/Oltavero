# Oltavero

## Run locally
Run `python3 -m http.server 8765 --bind 127.0.0.1` in this folder, then open http://127.0.0.1:8765/. A local server is required for authentication; opening index.html as a file is no longer supported.

## Supabase connection
Project: `fhtsefihwkxukpxzrpup` (Oltavero).
The frontend uses Supabase Auth and a public publishable key in `supabase-config.js`. No secret or service-role key is included. The official client is vendored locally and pinned to 2.118.0; its package integrity and license are recorded under `assets/vendor/supabase/`.

## Account flow
Create an account with your name, email and password. Email signup is enabled and email confirmation is required by the project. Confirm your address, then sign in. Your first company workspace is created from the company setup form. Sign out from the account dialog or Security settings. Sessions refresh automatically and survive page reloads.

For seamless confirmation redirects, configure Supabase Auth URL Configuration to allow `http://127.0.0.1:8765/` and `http://localhost:8765/`, plus the eventual production URL. The application requests the current origin as its email redirect. Existing project email delivery, rate limits and redirect configuration are retained; an actual email delivery/confirmation test was not performed.

## Real data and access
No demo company, employees, salary, approvals or charts are loaded. Old prototype data is never imported. Each company starts with its signed-in owner’s real name and email. Dashboard values come from company records; unavailable module data has empty states.

The database stores individual profiles, workspaces, owner memberships, versioned workspace documents and append-only database-generated audit events. All public tables have row-level security. Anonymous users cannot access records. A signed-in user can only read their own profile and workspaces where they have an owner membership. Clients cannot create or modify membership rows. Signup metadata is used for display names only, never authorization.

The current owner administration records (people, departments, company settings, module preferences and calendar events) persist to a versioned JSONB document per company. Concurrent stale revisions fail instead of silently overwriting changes. Profiles are independent per user. UI theme and selected company preferences are local; company records are stored in Supabase.

## Current boundaries
This release implements owner signup/login and company isolation. Employee roles remain classifications of records, not login permissions. Editing an employee record never grants account access. Additional-owner invitations/removals, non-owner role access, actual module workflows, document uploads, MFA enrollment and password recovery are not implemented. These require separate authorization and workflow work.

## Files
- `index.html`, `workspace.js`, `workspace.css`: authenticated product interface.
- `supabase-config.js`: public API configuration.
- `database/schema.sql`: schema already applied in Supabase; not an idempotent rerun script.
- `database/VERIFICATION.md`: tests performed and remaining verification limits.
- `design-system.html`, `tokens.css`, `tokens.json`: shared design system.
- `assets/icons/tabler/`, `tabler-icons.js`: local Tabler outline/filled icons and license.
- `assets/brand/`: transparent logo variant; the original logo is preserved at the root.

## Project advisor note
The final security advisor reported that leaked-password protection is disabled in Supabase Auth. Configure it in the project when available: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection. No RLS/schema security findings were reported. Performance checks only flagged newly created, not-yet-used indexes.
