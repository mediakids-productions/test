# 🔗 Implementation Guide: เชื่อม Google Sheet → Status Tracker Web

## สถาปัตยกรรมภาพรวม

```
Google Sheet (กรอกข้อมูล)
    ↓ Publish to Web (CSV)
    ↓
index.html (fetch CSV → parse → render)
    ↓
User ค้นหา Passport No. → แสดงผลแบบ Bento Grid
```

---

## ขั้นตอนที่ 1: ตั้งค่า Google Sheet

### 1.1 Import Template
1. เปิด Google Sheets → File → Import → Upload `StatusTracker_Template.xlsx`
2. เลือก "Replace spreadsheet"
3. Dropdown และสูตรจะทำงานอัตโนมัติ

### 1.2 Publish to Web
1. ไปที่ File → Share → Publish to web
2. เลือก Sheet "Tracker" → CSV format
3. กด Publish → คัดลอก URL ที่ได้
4. URL จะมีรูปแบบ:
```
https://docs.google.com/spreadsheets/d/e/{SHEET_ID}/pub?gid=0&single=true&output=csv
```

> ⚠️ ข้อมูลจะอัปเดตอัตโนมัติทุก ~5 นาที

---

## ขั้นตอนที่ 2: Column Mapping (สำคัญมาก!)

เว็บต้อง map ข้อมูลจาก CSV column ให้ตรงกับ Google Sheet:

```javascript
// Column Index Mapping (0-based จาก CSV)
const COL = {
  // Basic Info
  AREA: 0,           // A: Area
  SCHOOL: 1,         // B: School
  NAME: 2,           // C: Name
  PASSPORT: 3,       // D: Passport No.
  VISA_TYPE: 4,      // E: Visa Type

  // Visa
  VISA_PROC: 5,      // F: Procedure
  VISA_EXPIRE: 6,    // G: Expire Date
  VISA_EXPECTED: 7,  // H: Expected
  VISA_STATUS: 8,    // I: Status (auto)

  // Criminal Check
  CRIM_PROC: 9,      // J: Procedure
  CRIM_EXPECTED: 10,  // K: Expected
  CRIM_STATUS: 11,    // L: Status (auto)

  // Krusapa
  KRU_PROC: 12,      // M: Procedure
  KRU_ID: 13,        // N: ID
  KRU_EXPIRE: 14,    // O: Expire Date
  KRU_EXPECTED: 15,  // P: Expected
  KRU_STATUS: 16,    // Q: Status (auto)

  // Work Permit
  WP_PROC: 17,       // R: Procedure
  WP_ID: 18,         // S: ID
  WP_EXPIRE: 19,     // T: Expire Date
  WP_EXPECTED: 20,   // U: Expected
  WP_STATUS: 21,     // V: Status (auto)

  // Medical
  MED_PROC: 22,      // W: Procedure
  MED_EXPECTED: 23,  // X: Expected
  MED_STATUS: 24,    // Y: Status (auto)

  // Tax ID
  TAX_PROC: 25,      // Z: Procedure
  TAX_EXPECTED: 26,  // AA: Expected
  TAX_STATUS: 27,    // AB: Status (auto)

  // Bank
  BANK_PROC: 28,     // AC: Procedure
  BANK_EXPECTED: 29, // AD: Expected
  BANK_STATUS: 30,   // AE: Status (auto)

  // Visa Extension
  VEXT_PROC: 31,     // AF: Procedure
  VEXT_EXPECTED: 32, // AG: Expected
  VEXT_STATUS: 33,   // AH: Status (auto)

  // Overall
  OVERALL: 34,       // AI: Overall Progress (auto)
};
```

---

## ขั้นตอนที่ 3: อัปเดตโค้ดเว็บ

### 3.1 เปลี่ยน DEMO_DATA → Fetch จาก Google Sheet

**ลบ** `DEMO_DATA` array ทั้งหมด และเพิ่มฟังก์ชันนี้แทน:

```javascript
// ==========================================
// CONFIG - ใส่ URL ของ Google Sheet ที่ Publish แล้ว
// ==========================================
const SHEET_CSV_URL = 'https://docs.google.com/spreadsheets/d/e/YOUR_SHEET_ID/pub?gid=0&single=true&output=csv';

// ==========================================
// FETCH & PARSE CSV
// ==========================================
function parseCSV(csvText) {
  const lines = csvText.split('\n');
  const results = [];

  // Skip header rows (row 1 = section headers, row 2 = sub-headers)
  for (let i = 2; i < lines.length; i++) {
    const cols = parseCSVLine(lines[i]);
    if (!cols[COL.NAME] || !cols[COL.PASSPORT]) continue; // skip empty rows

    results.push({
      area: cols[COL.AREA] || '',
      school: cols[COL.SCHOOL] || '',
      name: cols[COL.NAME] || '',
      passportNo: cols[COL.PASSPORT] || '',
      visaType: cols[COL.VISA_TYPE] || '',

      visa: {
        status: cols[COL.VISA_STATUS] || 'Not Started',
        procedure: cols[COL.VISA_PROC] || '',
        expireDate: cols[COL.VISA_EXPIRE] || '',
        expectedDate: cols[COL.VISA_EXPECTED] || '',
        currentStep: getProcedureStep('visa', cols[COL.VISA_PROC]),
        steps: ["Apply", "Review", "Approved", "Collect"]
      },

      criminalCheck: {
        status: cols[COL.CRIM_STATUS] || 'Not Started',
        procedure: cols[COL.CRIM_PROC] || '',
        expectedDate: cols[COL.CRIM_EXPECTED] || '',
        currentStep: getProcedureStep('criminal', cols[COL.CRIM_PROC]),
        steps: ["Request", "Process", "Done"]
      },

      krusapa: {
        status: cols[COL.KRU_STATUS] || 'Not Started',
        procedure: cols[COL.KRU_PROC] || '',
        id: cols[COL.KRU_ID] || '',
        expireDate: cols[COL.KRU_EXPIRE] || '',
        expectedDate: cols[COL.KRU_EXPECTED] || '',
        currentStep: getProcedureStep('krusapa', cols[COL.KRU_PROC]),
        steps: ["Apply", "Verify", "Committee", "Issue"]
      },

      workPermit: {
        status: cols[COL.WP_STATUS] || 'Not Started',
        procedure: cols[COL.WP_PROC] || '',
        id: cols[COL.WP_ID] || '',
        expireDate: cols[COL.WP_EXPIRE] || '',
        expectedDate: cols[COL.WP_EXPECTED] || '',
        currentStep: getProcedureStep('workpermit', cols[COL.WP_PROC]),
        steps: ["Apply", "Review", "Pending", "Done"]
      },

      medical: {
        status: cols[COL.MED_STATUS] || 'Not Started',
        procedure: cols[COL.MED_PROC] || '',
        expectedDate: cols[COL.MED_EXPECTED] || '',
        currentStep: getProcedureStep('medical', cols[COL.MED_PROC]),
        steps: ["Book", "Exam", "Done"]
      },

      tax: {
        status: cols[COL.TAX_STATUS] || 'Not Started',
        procedure: cols[COL.TAX_PROC] || '',
        expectedDate: cols[COL.TAX_EXPECTED] || '',
        currentStep: getProcedureStep('tax', cols[COL.TAX_PROC]),
        steps: ["Apply", "Process", "Issue"]
      },

      bank: {
        status: cols[COL.BANK_STATUS] || 'Not Started',
        procedure: cols[COL.BANK_PROC] || '',
        expectedDate: cols[COL.BANK_EXPECTED] || '',
        currentStep: getProcedureStep('bank', cols[COL.BANK_PROC]),
        steps: ["Apply", "Process", "Done"]
      },

      visaExtension: {
        status: cols[COL.VEXT_STATUS] || 'Not Started',
        procedure: cols[COL.VEXT_PROC] || '',
        expectedDate: cols[COL.VEXT_EXPECTED] || '',
        currentStep: getProcedureStep('visaext', cols[COL.VEXT_PROC]),
        steps: ["Apply", "Review", "Approved"]
      }
    });
  }

  return results;
}

// CSV line parser (handles quoted fields with commas)
function parseCSVLine(line) {
  const result = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      result.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  result.push(current.trim());
  return result;
}

// Map procedure text → step number
function getProcedureStep(type, procedure) {
  if (!procedure || procedure === 'Not Started' || procedure === 'Not Required') return 0;

  const stepMaps = {
    visa:       { 'Applied': 1, 'Under Review': 2, 'Approved': 3, 'Collected': 4 },
    criminal:   { 'Requested': 1, 'Processing': 2, 'Completed': 3 },
    krusapa:    { 'Applied': 1, 'Verifying': 2, 'Committee Review': 3, 'Approved': 4, 'Issued': 5 },
    workpermit: { 'Applied': 1, 'Under Review': 2, 'Pending Approval': 3, 'Approved': 4 },
    medical:    { 'Booked': 1, 'Examined': 2, 'Completed': 3 },
    tax:        { 'Applied': 1, 'Processing': 2, 'Issued': 3 },
    bank:       { 'Applied': 1, 'Completed': 2 },
    visaext:    { 'Applied': 1, 'Under Review': 2, 'Approved': 3 }
  };

  return stepMaps[type]?.[procedure] || 0;
}
```

### 3.2 อัปเดตฟังก์ชัน searchStatus()

```javascript
// Global variable to store fetched data
let TEACHER_DATA = [];

async function searchStatus() {
  const passport = document.getElementById('passportInput').value.trim().toUpperCase();
  if (!passport) { alert('Please enter passport number'); return; }

  // Hide previous results
  document.getElementById('resultsSection').classList.remove('active');
  document.getElementById('errorMessage').classList.remove('active');
  document.getElementById('loading').classList.add('active');

  try {
    // Fetch fresh data from Google Sheet
    const response = await fetch(SHEET_CSV_URL);
    if (!response.ok) throw new Error('Failed to fetch data');

    const csvText = await response.text();
    TEACHER_DATA = parseCSV(csvText);

    // Search by passport number
    const data = TEACHER_DATA.find(d =>
      d.passportNo.toUpperCase() === passport
    );

    if (data) {
      displayResults(data);
    } else {
      document.getElementById('loading').classList.remove('active');
      document.getElementById('errorMessage').classList.add('active');
    }
  } catch (error) {
    console.error('Error fetching data:', error);
    document.getElementById('loading').classList.remove('active');
    document.getElementById('errorMessage').classList.add('active');
    document.getElementById('errorMessage').querySelector('p').textContent =
      'Unable to connect. Please try again.';
  }
}
```

### 3.3 อัปเดต displayResults() - เพิ่ม Expected Date

ใน `renderCard` function ให้เพิ่ม expected date:

```javascript
// เพิ่มใน details section ของ renderCard
if (data.expectedDate) {
  detailsHtml += `<div class="detail-row">
    <span class="detail-label">Expected</span>
    <span class="detail-value">${data.expectedDate}</span>
  </div>`;
}

// เพิ่ม procedure ด้วย
if (data.procedure && data.procedure !== 'Not Started') {
  detailsHtml += `<div class="detail-row">
    <span class="detail-label">Current Step</span>
    <span class="detail-value">${data.procedure}</span>
  </div>`;
}
```

### 3.4 อัปเดต renderActions() - ใช้ข้อมูลจาก Sheet

```javascript
// ใน renderActions ให้ใช้ procedure แทน waitingFor
if (statusClass === 'pending' || statusClass === 'in-progress') {
  actions.push({
    title: config.title,
    status: d.status,
    desc: d.procedure || 'Processing...',
    type: statusClass
  });
}
```

---

## ขั้นตอนที่ 4: เพิ่มฟีเจอร์ Overall Progress

เพิ่ม card ใหม่แสดง Overall Progress จากคอลัมน์ AI ของ Sheet:

```javascript
// เพิ่มใน teacher-card section
function renderOverallProgress(data) {
  // data.overall จะเป็น format "5/8" จาก Sheet
  const [done, total] = (data.overall || '0/0').split('/').map(Number);
  const percent = total > 0 ? Math.round((done / total) * 100) : 0;

  return `
    <div class="teacher-tag">
      <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
        <polyline points="22 4 12 14.01 9 11.01"/>
      </svg>
      <span>${done}/${total} Complete (${percent}%)</span>
    </div>
  `;
}
```

---

## ขั้นตอนที่ 5: Deployment

### Option A: GitHub Pages (ปัจจุบัน)
1. อัปเดต `index.html` ด้วยโค้ดใหม่
2. Push ไป GitHub
3. เว็บจะดึงข้อมูลจาก Google Sheet อัตโนมัติ

### Option B: Cloudflare Pages (แนะนำ)
1. เชื่อม GitHub repo กับ Cloudflare Pages
2. ได้ HTTPS + CDN ฟรี + unlimited bandwidth

---

## สรุป Workflow การใช้งาน

```
Admin (คุณ):
1. เปิด Google Sheet
2. กรอก/อัปเดต Procedure dropdown ของแต่ละ teacher
3. Status คำนวณอัตโนมัติ
4. ข้อมูลอัปเดตบนเว็บภายใน ~5 นาที

Teacher:
1. เปิดเว็บ Status Tracker
2. ใส่ Passport Number
3. เห็นสถานะทั้งหมดแบบ real-time
```

---

## Checklist สำหรับ Agent

- [ ] ลบ DEMO_DATA ออกจาก index.html
- [ ] เพิ่ม COL mapping object
- [ ] เพิ่ม parseCSV(), parseCSVLine(), getProcedureStep()
- [ ] อัปเดต searchStatus() ให้ fetch จาก Google Sheet
- [ ] อัปเดต displayResults() ให้รองรับ field ใหม่
- [ ] อัปเดต renderCard() เพิ่ม expectedDate, procedure
- [ ] อัปเดต renderActions() ใช้ procedure
- [ ] เพิ่ม Overall Progress display
- [ ] ใส่ SHEET_CSV_URL ที่ถูกต้อง
- [ ] ทดสอบ: กรอกข้อมูลใน Sheet → ค้นหาบนเว็บ → แสดงผลถูกต้อง
- [ ] ทดสอบ: เปลี่ยน Procedure → Status เปลี่ยนอัตโนมัติ
- [ ] ทดสอบ: Passport ไม่พบ → แสดง error message
- [ ] ทดสอบ: Responsive บน mobile
