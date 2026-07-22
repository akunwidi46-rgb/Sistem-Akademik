# TODO - Flutter + PHP+MySQL Academic Info System Audit

- [x] Step 1: Fix `HomePage._getProfilData()` request payload mapping and remove debug prints; avoid calling when role=admin.

- [x] Step 2: Add shared API client helper (`lib/services/api_client.dart`) for consistent POST/GET, headers, JSON parsing, and error handling.

- [x] Step 3: Refactor login/register/admin/profile calls to use helper and harden JSON decoding.

- [ ] Step 4: Refactor list/edit/add pages to use typed lists (`List<Map<String, dynamic>>`) and safer JSON handling.
- [ ] Step 5: Run `flutter analyze` and fix any lints/compile issues.
- [ ] Step 6: Run a basic smoke test by ensuring navigation works for Login->Dashboards->Lists->CRUD dialogs.
- [ ] Step 7: UI polish: responsive dialog sizing, consistent loading/empty/error states.
- [ ] Step 8: PHP/DB audit (blocked until PHP files are added to repo).
