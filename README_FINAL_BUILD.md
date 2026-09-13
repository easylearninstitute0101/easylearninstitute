# Easylearn Institute — Final Production Candidate

This ZIP is the final audited source package built from the previous production-fixed candidate.

## Student + Teacher academic portal

### Student
- Separate Student Portal after login.
- Enrolled batches.
- Assignments with deadline and description.
- Submit/update assignment with written answer and/or HTTPS file URL.
- Late status when submitted after deadline.
- Marks and teacher feedback.
- Recorded Classes for enrolled batches.
- YouTube URLs are embedded; other HTTPS video URLs open safely in a new tab.
- Fees, attendance and results remain available.

### Teacher
- Separate Teacher Portal after login.
- Own batches and routine.
- Create/manage assignments for permitted batches.
- Review student submissions for own assignments.
- Give marks and feedback.
- Add/manage recorded classes with HTTPS video URLs.

## Security

- Tenant isolation remains enforced with Supabase RLS.
- Student access is restricted to enrolled batches.
- Teacher academic access is scoped to their own teacher record / assigned batches.
- Assignment submissions are unique per student/assignment.
- Cross-tenant assignment/submission references are rejected by database triggers.
- No service-role/secret key is embedded in frontend source.

## Other production fixes in this package

The earlier fee, payment, monthly fee, attendance, expense, salary, reporting, portal linking, RPC authorization and private-photo fixes remain included. Missing live academic tables required by the frontend were also restored and secured during the final production pass.

## Verification status

- TypeScript static check: PASS.
- Live Supabase schema/policy verification: PASS.
- ZIP integrity: PASS.
- Real Vite build: not runnable in the current environment because `npm install` timed out and no local Vite binary was available.

### Deployment command

```bash
npm install
npm run build
```

Do not put a Supabase service-role/secret key in `.env` or frontend source.
