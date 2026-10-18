> Historical design prototype notes. The app now uses Supabase Auth and real company-scoped database records. See README.md and database/VERIFICATION.md for current behavior.

# Oltavero owner/admin design prototype

## Screen coverage
1. Owner overview — module summaries, workforce chart, department breakdown, approvals, activity.
2. Organization — departments, structure, location and schedule summary.
3. People directory — searchable and filterable records, role/status labels, selection and CSV exports.
4. Employee profile — overview, employment, HR/leave and private notes, compensation, documents, projects, access/history.
5. Roles and permissions — role creation, feature/action matrix, scopes and access preview.
6. Approvals — review with mandatory reason and persisted decision.
7. Calendar — October 2026 company events and sample event creation.
8. Reports — illustrative workforce chart and CSV exports.
9. Audit — browser-local activity log scoped by company.
10. Settings — company profile, module toggles, owners, security and appearance.
11. Company setup — guided profile, company and module selection.

## Reference translation
- Analytics examples: bordered white panels, compact controls, grouped metrics, line charts and ring breakdowns.
- Project dashboard: pastel icons, overview-first hierarchy and pending-work tables.
- Gumloop onboarding: quiet gradient canvas, centered forms and step progress.
- Untitled UI examples: table density, profile sections, owner management and focused dialogs.

The design uses the existing token stylesheet and retains Oltavero primary blue, responsive product typography, semantic status colors and accent families. The original logo is displayed without recoloring.

## Verification
JavaScript syntax check passed. Browser checks covered directory search, employee compensation tab, company isolation, permission preview and last-active-owner removal protection. Desktop and mobile dashboard layouts were visually inspected. Additional browser QA covers dialogs, setup, dark theme and other navigation.

## Limits
This is a local design prototype, not a backend. Records are fictional. No email is sent, files are not uploaded, and browser-local permissions/security/audit settings do not enforce production access. Dashboard and module values are illustrative. Complete module workflows and other role workspaces are deferred.

## Visual refinement 1.2
Replaced the screen stylesheet with a consistent type and spacing hierarchy driven by shared component tokens. Updated all admin views, tables, profiles, settings, dialogs and onboarding. Refined the banner and charts; added a light/dark chart-brand token. Desktop, tablet and mobile layouts are checked in the browser. Mobile profile identity uses a dedicated grid; hidden navigation is excluded from focus; keyboard tab-strip controls and Escape-to-close support are provided.

### Refinement validation
- Syntax check passed; browser console showed no JavaScript errors during the checked flows.
- Visually inspected desktop dashboard, directory, profile and invite dialog; tablet dashboard; mobile profile and settings; dark dashboard.
- Checked dashboard and directory width at 320px and checked the mobile invitation dialog opens.
- Organization, permissions, approvals, calendar, reports and audit rendered without document-wide overflow at the tested desktop viewport.
- Directory search and keyboard tab navigation passed after styling changes.
- Updated `dashboard-preview.jpg` and added `people-preview.jpg`.
