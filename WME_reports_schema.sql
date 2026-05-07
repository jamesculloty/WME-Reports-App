-- WME Reports App schema
-- Apply via Supabase MCP apply_migration or SQL editor.
-- Migration name: wme_reports_init

-- ── 1. timesheet_required flag on employees ──────────────────────────
-- Lets us exclude directors / non-timesheet staff from the compliance
-- check without hardcoding names.
ALTER TABLE employees
  ADD COLUMN IF NOT EXISTS timesheet_required boolean NOT NULL DEFAULT true;

UPDATE employees
  SET timesheet_required = false
  WHERE display_name IN ('James Culloty', 'Neil O''Sullivan', 'William Kelly');

-- ── 2. mgmt_actions — manager-voted to-do list ───────────────────────
CREATE TABLE IF NOT EXISTS mgmt_actions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title           text NOT NULL,
  detail          text,
  priority_score  integer NOT NULL DEFAULT 0,
  status          text NOT NULL DEFAULT 'open' CHECK (status IN ('open','done')),
  created_by      uuid REFERENCES employees(id),
  created_at      timestamptz NOT NULL DEFAULT now(),
  completed_by    uuid REFERENCES employees(id),
  completed_at    timestamptz
);

CREATE INDEX IF NOT EXISTS mgmt_actions_status_priority_idx
  ON mgmt_actions (status, priority_score DESC, created_at DESC);

ALTER TABLE mgmt_actions ENABLE ROW LEVEL SECURITY;

-- Manager / admin read everything
DROP POLICY IF EXISTS mgmt_actions_select ON mgmt_actions;
CREATE POLICY mgmt_actions_select ON mgmt_actions
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM employees e
      WHERE e.auth_email = auth.email()
        AND e.role IN ('manager','admin')
    )
  );

-- Manager / admin insert
DROP POLICY IF EXISTS mgmt_actions_insert ON mgmt_actions;
CREATE POLICY mgmt_actions_insert ON mgmt_actions
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM employees e
      WHERE e.auth_email = auth.email()
        AND e.role IN ('manager','admin')
    )
  );

-- Manager / admin update (vote / mark done)
DROP POLICY IF EXISTS mgmt_actions_update ON mgmt_actions;
CREATE POLICY mgmt_actions_update ON mgmt_actions
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM employees e
      WHERE e.auth_email = auth.email()
        AND e.role IN ('manager','admin')
    )
  );

-- Admin only delete (so anyone can mark done but only admin can hard-remove)
DROP POLICY IF EXISTS mgmt_actions_delete ON mgmt_actions;
CREATE POLICY mgmt_actions_delete ON mgmt_actions
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM employees e
      WHERE e.auth_email = auth.email()
        AND e.role = 'admin'
    )
  );
