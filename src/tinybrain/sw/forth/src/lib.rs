#![no_std]

extern crate alloc;

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;

#[derive(Clone)]
pub enum Data {
    Number(i64),
    // Function,
    // String,
}

type Handler = fn(&mut Context, &mut dyn Iterator<Item = &str>) -> Result<(), String>;

// Could have used a hashmap, but that has consequences, as we all know
type Handlers = Vec<(String, Handler)>;

fn add(ctx: &mut Context, _word_iter: &mut dyn Iterator<Item = &str>) -> Result<(), String> {
    let a = ctx.pop_number()?;
    let b = ctx.pop_number()?;

    ctx.push_number(a + b);

    Ok(())
}

fn multiply(ctx: &mut Context, _word_iter: &mut dyn Iterator<Item = &str>) -> Result<(), String> {
    let a = ctx.pop_number()?;
    let b = ctx.pop_number()?;

    ctx.push_number(a * b);

    Ok(())
}

fn dup(ctx: &mut Context, _word_iter: &mut dyn Iterator<Item = &str>) -> Result<(), String> {
    let entry = ctx.pop()?;
    ctx.push(entry.clone());
    ctx.push(entry);

    Ok(())
}

fn drop(ctx: &mut Context, _word_iter: &mut dyn Iterator<Item = &str>) -> Result<(), String> {
    let _entry = ctx.pop()?;
    Ok(())
}

fn swap(ctx: &mut Context, _word_iter: &mut dyn Iterator<Item = &str>) -> Result<(), String> {
    let a = ctx.pop()?;
    let b = ctx.pop()?;
    ctx.push(a);
    ctx.push(b);
    Ok(())
}

fn over(ctx: &mut Context, _word_iter: &mut dyn Iterator<Item = &str>) -> Result<(), String> {
    let a = ctx.pop()?;
    let b = ctx.pop()?;
    ctx.push(b.clone());
    ctx.push(a);
    ctx.push(b);
    Ok(())
}

fn consume_and_display(
    ctx: &mut Context,
    _word_iter: &mut dyn Iterator<Item = &str>,
) -> Result<(), String> {
    let entry = ctx.pop()?;
    match entry {
        Data::Number(num) => ctx.output.push_str(&format!("{num}")),
    }

    Ok(())
}

pub struct Context {
    handlers: Handlers,
    stack: Vec<Data>,
    output: String,
}

impl Default for Context {
    fn default() -> Self {
        Self {
            handlers: vec![
                ("+".to_string(), add),
                ("*".to_string(), multiply),
                (".".to_string(), consume_and_display),
                ("dup".to_string(), dup),
                ("drop".to_string(), drop),
                ("swap".to_string(), swap),
                ("over".to_string(), over),
            ],
            stack: vec![],
            output: String::new(),
        }
    }
}

impl Context {
    pub fn new() -> Self {
        Default::default()
    }

    fn pop(&mut self) -> Result<Data, String> {
        self.stack.pop().ok_or_else(|| "Stack is empty".to_string())
    }

    fn pop_number(&mut self) -> Result<i64, String> {
        match self.stack.pop() {
            Some(Data::Number(a)) => Ok(a),
            Some(_) => Err("".to_string()),
            None => Err("".to_string()),
        }
    }

    fn push(&mut self, entry: Data) {
        self.stack.push(entry);
    }

    fn push_number(&mut self, number: i64) {
        self.stack.push(Data::Number(number));
    }

    fn out(&mut self) -> String {
        core::mem::take(&mut self.output)
    }
}

pub fn interpret(ctx: &mut Context, line: &str) -> Result<String, String> {
    let mut iter = line.split_whitespace();
    while let Some(word) = iter.next() {
        if let Some(handler) = ctx
            .handlers
            .iter()
            .find(|(n, _fn)| n == word)
            .map(|(_n, f)| f)
        {
            handler(ctx, &mut iter)?;
        } else if let Ok(number) = word.parse::<i64>() {
            ctx.stack.push(Data::Number(number));
        }
    }
    Ok(ctx.out())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn construct_context() {
        let ctx = Context::new();
        assert_eq!(ctx.stack.len(), 0);
    }

    #[test]
    fn most_basic_test() {
        let mut ctx = Context::new();
        interpret(&mut ctx, "  12345   12345   + 10 *  . ").unwrap();
        assert_eq!(ctx.output, "246900");
    }
}
