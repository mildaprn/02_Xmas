/**
 * Luka's Letter to Santa: the small "database" behind the website.
 *
 * This script lives inside a Google Sheet (Extensions > Apps Script) and is
 * published as a web app. The website talks to it to list, reserve and cancel
 * gifts. Reservations are stored as rows on the sheet "Rezervacijos".
 *
 * What the website can learn from it:
 *   - which gifts are reserved, and whether a reservation is the caller's own;
 *   - nothing else. Names and secret codes are never sent to the website.
 *
 * Who reserved what: open the Google Sheet and look at the column "Kas rezervavo".
 * To clear a reservation, delete its row in the Sheet.
 */

var SHEET_NAME = "Rezervacijos";
var HEADERS = ["Dovana", "Kas rezervavo", "Slaptas kodas", "Kada"];
var ID_PATTERN = /^[a-z0-9_-]{1,40}$/;

function getSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName(SHEET_NAME);
  if (!sh) { sh = ss.insertSheet(SHEET_NAME); }
  if (sh.getLastRow() === 0) {
    sh.appendRow(HEADERS);
    sh.setFrozenRows(1);
  }
  return sh;
}

// A short message you can open in a browser to check that the web app is running.
function doGet() {
  return json_({ ok: true, message: "Luka's Santa list is running." });
}

function doPost(e) {
  var out;
  try {
    var req = JSON.parse(e.postData.contents);
    // One request at a time, so two people tapping together cannot both reserve the same gift.
    var lock = LockService.getScriptLock();
    lock.waitLock(10000);
    try {
      out = handle_(req);
    } finally {
      lock.releaseLock();
    }
  } catch (err) {
    out = { ok: false, error: String((err && err.message) || err) };
  }
  return json_(out);
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}

function handle_(req) {
  var sh = getSheet_();
  var count = Math.max(sh.getLastRow() - 1, 0);
  var rows = count > 0 ? sh.getRange(2, 1, count, 3).getValues() : [];
  var owner = "c_" + String(req.owner || "");   // the prefix stops Sheets from turning a code into a number

  function indexOfGift(gift) {
    for (var i = 0; i < rows.length; i++) {
      if (String(rows[i][0]) === gift) { return i; }
    }
    return -1;
  }

  if (req.action === "list") {
    var list = [];
    for (var i = 0; i < rows.length; i++) {
      if (rows[i][0] !== "") {
        list.push({ gift_id: String(rows[i][0]), mine: String(rows[i][2]) === owner && String(req.owner || "").length >= 16 });
      }
    }
    return { ok: true, reservations: list };
  }

  var gift = String(req.gift || "");
  if (!ID_PATTERN.test(gift)) { throw new Error("bad_request"); }
  if (String(req.owner || "").length < 16 || String(req.owner).length > 80) { throw new Error("bad_request"); }

  if (req.action === "reserve") {
    var member = String(req.member || "");
    if (!ID_PATTERN.test(member)) { throw new Error("bad_request"); }
    if (indexOfGift(gift) !== -1) { return { ok: true, reserved: false }; }
    sh.appendRow([gift, member, owner, new Date()]);
    return { ok: true, reserved: true };
  }

  if (req.action === "release") {
    var idx = indexOfGift(gift);
    if (idx === -1) { return { ok: true, result: "ok" }; }
    if (String(rows[idx][2]) !== owner) { return { ok: true, result: "not_owner" }; }
    sh.deleteRow(idx + 2);
    return { ok: true, result: "ok" };
  }

  throw new Error("bad_request");
}
