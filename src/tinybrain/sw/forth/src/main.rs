use std::io::Write;

use forth::{Context, interpret};

fn main() -> Result<(), String> {
    let mut ctx = Context::new();

    loop {
        print!("ok ");
        std::io::stdout()
            .flush()
            .map_err(|e| format!("Error flushing stdout: {e:?}"))?;
        let mut s = String::new();
        std::io::stdin()
            .read_line(&mut s)
            .map_err(|e| format!("Unable to read stdin {e:?}"))?;
        let res = interpret(&mut ctx, &s)?;
        if !res.is_empty() {
            print!("{res} ");
        }
    }
}
