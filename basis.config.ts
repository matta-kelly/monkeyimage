// The config of `basis lint`, from monkeyimage's root: its schema gives its notes and what is not a note.
import type { Config } from "@mku1tra/basis";
import monkeyimage from "./schema.ts";

export default { schema: monkeyimage } satisfies Config;
