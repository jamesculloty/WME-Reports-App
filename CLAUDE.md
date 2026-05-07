# WME Reports App — Project Context

## What this is
Management reports / KPI dashboard for Watford ME Ltd (M&E contractor).
Single HTML file (`index.html`) with Supabase backend.
Part of the WME app suite — shares Supabase project and auth with all other WME apps.
Manager / admin access only — pulls data from every other app for at-a-glance management view.

## Live URLs
- App: https://reports.watfordme.co.uk (Vercel: wme-reports-app)
- GitHub: https://github.com/jamesculloty/WME-Reports-App
- Supabase project: zzajwyyhyioaqtyyislc (shared with all WME apps)

## Authentication
Uses the shared WMEAuth module loaded from https://apps.watfordme.co.uk/wme-auth.js
Cross-subdomain SSO via shared cookie on .watfordme.co.uk
Role-based access: manager, admin only
ADMIN_EMAIL: jamesculloty@watfordme.co.uk

## Database (Supabase PostgreSQL — shared project)

### Tables this app reads from
- `applications`, `application_lines`, `variations`, `cvr_projects` (CVR app)
- `time_entries`, `employees`, `timesheets` (Timesheet app)
- `invoices`, `po_log`, `vendors`, `projects` (Procurement / Invoice apps)
- `earned_values`, `client_work_log`, `maintenance_clients` (Maintenance app)

### Tables introduced by this app
- `mgmt_actions` — manual to-do list with up/down voting:
  id, title, detail, priority_score (int), status ('open'|'done'),
  created_by, created_at, completed_by, completed_at
- adds `timesheet_required boolean default true` column to `employees`
  so directors / non-timesheet staff can be excluded from the
  compliance check without code changes.

## Stack
- Vanilla HTML/CSS/JS — no framework, no build process
- Supabase JS v2 (unpkg CDN)
- Chart.js (jsDelivr CDN) — bar / line charts
- WMEAuth shared auth module (apps.watfordme.co.uk)
- Deployed as static file on Vercel with custom domain
- Auto-deploys on every GitHub push to main branch

## Key conventions
- All code lives in one file: index.html
- WME brand colours: green #1D4A2A, gold #B8860B
- After every change: commit with a clear message and push to main
- App switcher bar rendered by WMEAuth.renderAppSwitcher()

## Screens
1. scr-auth — Login (shared auth)
2. scr-dash — The dashboard (one screen, multiple cards)
3. scr-no-employee — Auth email not linked to employee
4. scr-no-access — Role insufficient (operative/maintenance/office)

## Widgets on the dashboard
1. **KPI strip** — work in hand · cash position · this-month revenue ·
   forecast margin · maintenance 12wk net
2. **Project revenue vs cost — last 3 months** — table per active
   contract project: revenue (certified or applied) and cost
   (timesheet labour + invoices) for each of the last 3 calendar months
3. **Top 5 suppliers** — bar chart of `invoices.net_amount`
   summed by `vendor_name`, last 90 days, status Approved/Exported
4. **Action items board** — `mgmt_actions` table. Anyone manager+ can
   add, ↑/↓ vote (priority_score ±1), or mark done.
5. **Timesheet compliance** — active employees with `timesheet_required=true`
   who have NO `timesheets` row for last week (Mon–Fri of previous calendar
   week) with status in ('Submitted', 'Approved')
6. **Margin RAG** — every active Contract project sorted by % margin,
   red <5%, amber <10%, green ≥10%
7. **Maintenance health** — active client count, revenue last 12wk,
   Shannon's revenue-needed queue size, top 5 clients by revenue last 12 months

## Revenue convention
"Revenue this period" for a delivery project:
- if the application is Certified or Paid → use `applications.this_certified`
- else (Draft / Submitted) → use `net_application − previous_certified`
i.e. the certified value when received, the applied value otherwise.

## "Last week" convention (timesheet compliance)
Mon–Fri of the previous calendar week (e.g. today Wed 7 May → check
Mon 28 Apr to Fri 2 May). Differs from the CVR Tue–Mon convention,
since timesheets are framed Mon–Fri elsewhere in the suite.

## Permanent timesheet exclusions (set via column flag)
- James Culloty
- Neil O'Sullivan
- William Kelly
Future directors flip `timesheet_required = false`, no code change.

## Current status
- Initial scaffold — app being built
