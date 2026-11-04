/**
 * monkeyimage: its notes, on the note types of it. It defines no types of its own.
 */

import { defineSchema } from "@mku1tra/basis";
import it from "@mku1tra/it";

/** Whether a path of the repo, from its root, is not a note: a README. */
const skip = (path: string) => ["README.md", "AGENTS.md"].includes(path.split("/").at(-1) ?? ""); // AGENTS.md is instructions for an agent, not a note

export default defineSchema({
  name: "monkeyimage",
  description: "monkeyimage's notes, on the note types of it.",
  types: {},
  imports: [it],
  notes: new URL("./", import.meta.url),
  skip,
  exports: () => import("./schema.ts"),
});
