#!/usr/bin/env python3
import tkinter as tk
import threading
import time
import sys
import subprocess
import os

def pick_file():
    try:
        result = subprocess.run([
            'osascript', '-e',
            'set f to choose file with prompt "选择要阅读的文本文件" of type {"public.plain-text", "public.html"}'
        ], capture_output=True, text=True, timeout=10)
        path = result.stdout.strip()
        if path:
            path = path.replace('alias ', '').strip()
            from urllib.parse import unquote
            if path.startswith('/'):
                return path
            if path.startswith('Macintosh HD'):
                path = '/' + path.split('Macintosh HD')[-1]
            return path
        return None
    except:
        return None

class InvisibleReader:
    def __init__(self, filepath):
        self.filepath = filepath
        self.lines = self.load_text()
        self.current_line = 0
        self.hide_after_id = None

        self.root = tk.Tk()
        self.root.title("隐身阅读器")
        self.root.overrideredirect(True)
        self.root.attributes('-topmost', True)
        self.root.configure(bg='black')
        self.root.attributes('-alpha', 0.95)

        screen_w = self.root.winfo_screenwidth()
        screen_h = self.root.winfo_screenheight()
        win_w = 420
        win_h = min(500, screen_h - 40)
        self.x = screen_w - win_w - 20
        self.y = 10
        self.win_w = win_w
        self.win_h = win_h
        self.screen_w = screen_w

        self.text_widget = tk.Text(
            self.root, wrap='word', bg='#1a1a2e', fg='#e0e0e0',
            font=('SF Mono', 14), padx=20, pady=20,
            borderwidth=0, highlightthickness=0,
            insertbackground='#e0e0e0'
        )
        self.text_widget.pack(fill='both', expand=True)
        self.text_widget.bind('<Button-1>', self.next_page)
        self.text_widget.bind('<Button-3>', self.prev_page)
        self.text_widget.tag_configure('title', font=('SF Mono', 16, 'bold'), foreground='#ff6b6b', spacing1=10)
        self.text_widget.tag_configure('sep', foreground='#4a4a6a')
        self.text_widget.config(state='disabled')

        self.root.bind('<Escape>', lambda e: self.hide())
        self.root.bind('<Right>', lambda e: self.next_page())
        self.root.bind('<Left>', lambda e: self.prev_page())
        self.root.bind('<Up>', lambda e: self.prev_page())
        self.root.bind('<space>', lambda e: self.next_page())

        self.root.withdraw()
        self.visible = False
        self.mouse_monitor_running = True
        threading.Thread(target=self.monitor_mouse, daemon=True).start()

    def load_text(self):
        try:
            with open(self.filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            content = content.replace('\r\n', '\n').replace('\r', '\n')
            paragraphs = [p.strip() for p in content.split('\n') if p.strip()]
            return paragraphs if paragraphs else ['（文件为空）']
        except FileNotFoundError:
            return [f'文件未找到:\n{self.filepath}']
        except Exception as e:
            return [f'读取错误:\n{str(e)}']

    def show(self):
        if not self.visible:
            self.root.geometry(f'{self.win_w}x{self.win_h}+{self.x}+{self.y}')
            self.root.deiconify()
            self.root.lift()
            self.visible = True
            self.render_page()
        if self.hide_after_id:
            self.root.after_cancel(self.hide_after_id)
            self.hide_after_id = None

    def hide(self):
        if self.visible:
            self.root.withdraw()
            self.visible = False

    def schedule_hide(self):
        if self.hide_after_id:
            self.root.after_cancel(self.hide_after_id)
        self.hide_after_id = self.root.after(500, self.hide)

    def render_page(self):
        self.text_widget.config(state='normal')
        self.text_widget.delete('1.0', 'end')

        remaining = self.lines[self.current_line:]
        if not remaining:
            self.text_widget.insert('end', '— 已到末尾 —\n\n（点击返回开头）')
            self.text_widget.config(state='disabled')
            return

        max_chars = 600
        chars = 0
        page_lines = []
        for line in remaining:
            page_lines.append(line)
            chars += len(line)
            if chars >= max_chars:
                break

        display_text = '\n\n'.join(page_lines)

        if self.current_line == 0 and self.lines:
            title_line = self.lines[0]
            if len(title_line) < 50:
                rest = display_text[len(title_line):].strip()
                self.text_widget.insert('end', title_line + '\n', 'title')
                self.text_widget.insert('end', '─' * 30 + '\n', 'sep')
                if rest:
                    self.text_widget.insert('end', rest)
            else:
                self.text_widget.insert('end', display_text)
        else:
            self.text_widget.insert('end', display_text)

        end_idx = self.current_line + len(page_lines)
        page_info = f'\n\n[{self.current_line + 1}-{end_idx} / {len(self.lines)}]'
        self.text_widget.insert('end', page_info, 'sep')
        self.text_widget.config(state='disabled')

    def next_page(self, event=None):
        if not self.visible:
            return
        total_shown = 0
        chars = 0
        for line in self.lines[self.current_line:]:
            total_shown += 1
            chars += len(line)
            if chars >= 600:
                break
        if self.current_line + total_shown < len(self.lines):
            self.current_line += total_shown
        else:
            self.current_line = 0
        self.render_page()

    def prev_page(self, event=None):
        if not self.visible:
            return
        target = max(0, self.current_line - 30)
        self.current_line = target
        self.render_page()

    def is_mouse_in_hotzone(self):
        x, y = self.root.winfo_pointerxy()
        return x > self.screen_w - 10 and y < 10

    def is_mouse_on_window(self):
        if not self.visible:
            return False
        try:
            x, y = self.root.winfo_pointerxy()
            wx = self.root.winfo_x()
            wy = self.root.winfo_y()
            return wx <= x <= wx + self.win_w and wy <= y <= wy + self.win_h
        except:
            return False

    def monitor_mouse(self):
        while self.mouse_monitor_running:
            try:
                in_hotzone = self.is_mouse_in_hotzone()
                on_window = self.is_mouse_on_window()

                if in_hotzone:
                    self.root.after(0, self.show)
                elif self.visible and not on_window:
                    self.root.after(0, self.schedule_hide)
                elif self.visible and on_window:
                    if self.hide_after_id:
                        self.root.after_cancel(self.hide_after_id)
                        self.hide_after_id = None

                time.sleep(0.1)
            except:
                time.sleep(0.1)

    def run(self):
        self.root.mainloop()


if __name__ == '__main__':
    path = None
    if len(sys.argv) > 1:
        path = sys.argv[1]
        path = path.strip().strip('"').strip("'")
        if not os.path.isfile(path):
            path = None
    if not path:
        path = pick_file()
    if not path:
        sys.exit(0)
    app = InvisibleReader(path)
    app.run()
