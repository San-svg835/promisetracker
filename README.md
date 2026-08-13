# 🇮🇳 PromiseTrack

### Building a Transparent Bharat, One Ward at a Time.

PromiseTrack is a **Civic Tech platform** designed to connect citizens with local representatives through transparent issue reporting, AI-powered prioritization, project tracking, budget monitoring, and citizen verification.

> **Report → Prioritize → Resolve → Verify → Track**

---

## 🚨 Problem Statement

Civic issues such as damaged roads, water leakage, broken streetlights, waste accumulation, drainage problems, and public safety concerns often go unresolved because of:

- Lack of transparent issue tracking
- Difficulty in identifying high-priority problems
- Limited citizen participation
- Poor visibility into project progress
- Lack of transparency in public fund utilization
- Difficulty verifying whether a reported issue has actually been resolved
- Limited accountability between citizens and local authorities

Citizens report problems, but often have no clear way to know:

**What happens after the complaint is submitted?**

PromiseTrack addresses this gap by creating a transparent digital bridge between citizens and local representatives.

---

# 💡 Our Solution

PromiseTrack provides a unified platform where:

### 👤 Citizens can
- Report civic issues
- Upload photographic evidence
- Track issue status
- View issues on a civic map
- Upvote existing issues
- Verify completed work
- Dispute false or incomplete resolutions
- View public transparency reports

### 🏛️ Local Representatives can
- Monitor civic issues
- Prioritize problems based on urgency
- Manage projects
- Track budgets
- Upload resolution evidence
- Respond to citizen disputes
- Monitor ward performance
- Generate public transparency reports

---

# ⭐ Key Differentiators

## 1. 🤖 AI Civic Priority Engine

Instead of treating every complaint equally, PromiseTrack calculates a **Priority Score from 0–100**.

The score considers:

- Severity
- Number of affected citizens
- Safety risk
- Issue age
- Location sensitivity

### Example

**Priority Score: 94 / 100**

| Factor | Score |
|---|---:|
| Severity | 22/25 |
| Affected Citizens | 20/20 |
| Safety Risk | 25/25 |
| Issue Age | 15/15 |
| Location Sensitivity | 12/15 |

The system also generates a plain-language explanation:

> "This issue has a high safety risk, affects many citizens and is located near a sensitive public location."

Issues are automatically categorized into:

| Score | Priority |
|---|---|
| 90–100 | 🔴 Critical |
| 75–89 | 🟠 High |
| 50–74 | 🟡 Medium |
| 0–49 | 🟢 Low |

This creates a transparent and explainable prioritization system.

---

# 📸 2. Photo-Proof Verification

PromiseTrack uses photographic evidence to improve accountability.

### Before Resolution

Citizens upload a **Before Photo** when reporting an issue.

### After Resolution

Officials upload an **After Photo** when marking the issue as completed.

The platform can associate evidence with:

- Timestamp
- Location/geotag
- Issue
- Resolution status

### Citizen Dispute

If a citizen believes the issue has not actually been resolved, they can submit a counter-photo and dispute the resolution.

Repeated disputes can move the issue back into the priority queue.

This creates a:

**Citizen → Authority → Citizen Verification**

feedback loop.

---

# 💰 3. Budget Transparency

PromiseTrack tracks public project budgets.

Administrators can manage:

- Allocated budget
- Released budget
- Utilized budget
- Remaining budget
- Project progress

The system visualizes:

**Allocated vs Utilized**

This helps citizens understand how public funds are being used.

---

# 📊 4. Public Transparency Reports

Administrators can generate ward-level transparency reports.

Reports include:

- Total issues
- Resolved issues
- Delayed issues
- Disputed issues
- Average resolution time
- Priority distribution
- Top unresolved high-priority issues
- Budget utilization
- Project progress
- Transparency score
- Before/After evidence

Reports can be:

- Previewed
- Generated
- Exported as PDF
- Shared using a public link

Public reports can be accessed without requiring login.

---

# 🗺️ 5. Civic Map

The Civic Map provides a geographical view of reported issues.

Issues are color-coded according to priority:

🔴 Critical  
🟠 High  
🟡 Medium  
🟢 Low / Resolved

Users can select an issue marker to view its details.

---

# 👥 User Roles

PromiseTrack provides two distinct experiences.

## 👤 Citizen

Citizen navigation:

- Dashboard
- Report Issue
- My Issues
- Civic Map
- Projects
- Reports
- Profile
- Settings
- Logout

Citizens can:

- Report problems
- Upload evidence
- Track complaints
- Upvote issues
- Verify resolutions
- Raise disputes
- View public reports

---

## 🏛️ Admin / Local Representative

Admin navigation:

- Overview
- Priority Queue
- Issues
- Projects
- Budgets
- Reports
- Analytics
- Profile
- Settings
- Logout

Administrators can:

- Monitor priority issues
- Manage complaints
- Assign officials
- Update project status
- Manage budgets
- Upload resolution evidence
- Handle disputes
- Analyze ward performance
- Generate transparency reports

The Admin Dashboard is designed as a:

### **Civic Operations Control Center**

---

# 📱 Main Features

### Authentication
- Citizen registration
- Admin registration
- Login
- Logout
- Password validation
- Password reset
- Role-based navigation

### Issue Management
- Create civic issue
- Issue categories
- Issue status tracking
- Priority scoring
- Issue upvotes
- Issue details
- Issue history

### Evidence
- Before photos
- After photos
- Citizen counter-evidence
- Timestamp/location metadata
- Resolution verification

### Projects
- Project tracking
- Project progress
- Project status
- Official responsible
- Timeline
- Budget information

### Budget Management
- Budget allocation
- Budget utilization
- Remaining budget
- Project-wise budget tracking
- Visualization

### Analytics
- Priority distribution
- Issue status
- Resolution rate
- Average resolution time
- Ward performance
- Budget utilization
- Dispute rate

### Reports
- Ward-level reports
- Date-range reports
- Report preview
- PDF generation
- Public report links

---

# 🎨 Design

PromiseTrack uses an **Independence Day-inspired visual identity**.

### Primary Colors

🟠 Orange  
`#F28C28`

🟢 Green  
`#138808`

### Ashoka Chakra

🔵 Navy Blue  
`#000080`

The Ashoka Chakra is used as a subtle visual element on the landing page.

The functional priority colors remain separate from the branding to maintain usability and accessibility.

---

# 🏗️ System Architecture

```text
                    ┌──────────────────────┐
                    │      CITIZEN         │
                    │                      │
                    │ Report / Track /     │
                    │ Verify / Dispute     │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │    PROMISETRACK      │
                    │      PLATFORM        │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
       ┌────────────┐   ┌──────────────┐  ┌─────────────┐
       │ AI Priority│   │ Issue /      │  │ Photo       │
       │ Engine     │   │ Project Mgmt │  │ Verification│
       └────────────┘   └──────────────┘  └─────────────┘
              │                │                │
              └────────────────┼────────────────┘
                               ▼
                    ┌──────────────────────┐
                    │      DATABASE        │
                    │                      │
                    │ Users                │
                    │ Issues               │
                    │ Projects             │
                    │ Budgets              │
                    │ Reports              │
                    │ Disputes              │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │       ADMIN          │
                    │                      │
                    │ Monitor / Manage /   │
                    │ Resolve / Analyze    │
                    └──────────────────────┘
Priority Score =
    Severity
  + Affected Citizens
  + Safety Risk
  + Issue Age
  + Location Sensitivity
