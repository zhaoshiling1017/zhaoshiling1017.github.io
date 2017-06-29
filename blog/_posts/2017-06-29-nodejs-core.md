---
layout: post
title: NodeJs核心模块介绍
category: thinking
---

# JavaScript核心模块的编译过程

在编译所有C/C++文件之前，编译程序需要将所有的JavaScript模块文件编译成C/C++代码，此时是否直接将其编译成可执行代码了呢？其实不是。

* 转存为C/C++代码

Node采用V8附带的`j2c.py`工具，将所有内置的JavaScript代码(src/node.js和lib/\*.js)转化为C++里的数组，生成`node_natives.h`头文件，相关代码如下：

`j2c.py`文件内容：

```
import os
from os.path import dirname
import re
import sys
import string

sys.path.append(dirname(__file__) + "/../deps/v8/tools");
import jsmin


def ToCArray(filename, lines):
  result = []
  row = 1
  col = 0
  for chr in lines:
    col += 1
    if chr == "\n" or chr == "\r":
      row += 1
      col = 0

    value = ord(chr)

    if value >= 128:
      print 'non-ascii value ' + filename + ':' + str(row) + ':' + str(col)
      sys.exit(1);

    result.append(str(value))
  result.append("0")
  return ", ".join(result)


def CompressScript(lines, do_jsmin):
  # If we're not expecting this code to be user visible, we can run it through
  # a more aggressive minifier.
  if do_jsmin:
    minifier = JavaScriptMinifier()
    return minifier.JSMinify(lines)

  # Remove stuff from the source that we don't want to appear when
  # people print the source code using Function.prototype.toString().
  # Note that we could easily compress the scripts mode but don't
  # since we want it to remain readable.
  #lines = re.sub('//.*\n', '\n', lines) # end-of-line comments
  #lines = re.sub(re.compile(r'/\*.*?\*/', re.DOTALL), '', lines) # comments.
  #lines = re.sub('\s+\n+', '\n', lines) # trailing whitespace
  return lines


def ReadFile(filename):
  file = open(filename, "rt")
  try:
    lines = file.read()
  finally:
    file.close()
  return lines


def ReadLines(filename):
  result = []
  for line in open(filename, "rt"):
    if '#' in line:
      line = line[:line.index('#')]
    line = line.strip()
    if len(line) > 0:
      result.append(line)
  return result


def LoadConfigFrom(name):
  import ConfigParser
  config = ConfigParser.ConfigParser()
  config.read(name)
  return config


def ParseValue(string):
  string = string.strip()
  if string.startswith('[') and string.endswith(']'):
    return string.lstrip('[').rstrip(']').split()
  else:
    return string


def ExpandConstants(lines, constants):
  for key, value in constants.items():
    lines = lines.replace(key, str(value))
  return lines


def ExpandMacros(lines, macros):
  for name, macro in macros.items():
    start = lines.find(name + '(', 0)
    while start != -1:
      # Scan over the arguments
      assert lines[start + len(name)] == '('
      height = 1
      end = start + len(name) + 1
      last_match = end
      arg_index = 0
      mapping = { }
      def add_arg(str):
        # Remember to expand recursively in the arguments
        replacement = ExpandMacros(str.strip(), macros)
        mapping[macro.args[arg_index]] = replacement
      while end < len(lines) and height > 0:
        # We don't count commas at higher nesting levels.
        if lines[end] == ',' and height == 1:
          add_arg(lines[last_match:end])
          last_match = end + 1
        elif lines[end] in ['(', '{', '[']:
          height = height + 1
        elif lines[end] in [')', '}', ']']:
          height = height - 1
        end = end + 1
      # Remember to add the last match.
      add_arg(lines[last_match:end-1])
      result = macro.expand(mapping)
      # Replace the occurrence of the macro with the expansion
      lines = lines[:start] + result + lines[end:]
      start = lines.find(name + '(', end)
  return lines

class TextMacro:
  def __init__(self, args, body):
    self.args = args
    self.body = body
  def expand(self, mapping):
    result = self.body
    for key, value in mapping.items():
        result = result.replace(key, value)
    return result

class PythonMacro:
  def __init__(self, args, fun):
    self.args = args
    self.fun = fun
  def expand(self, mapping):
    args = []
    for arg in self.args:
      args.append(mapping[arg])
    return str(self.fun(*args))

CONST_PATTERN = re.compile('^const\s+([a-zA-Z0-9_]+)\s*=\s*([^;]*);$')
MACRO_PATTERN = re.compile('^macro\s+([a-zA-Z0-9_]+)\s*\(([^)]*)\)\s*=\s*([^;]*);$')
PYTHON_MACRO_PATTERN = re.compile('^python\s+macro\s+([a-zA-Z0-9_]+)\s*\(([^)]*)\)\s*=\s*([^;]*);$')

def ReadMacros(lines):
  constants = { }
  macros = { }
  for line in lines:
    hash = line.find('#')
    if hash != -1: line = line[:hash]
    line = line.strip()
    if len(line) is 0: continue
    const_match = CONST_PATTERN.match(line)
    if const_match:
      name = const_match.group(1)
      value = const_match.group(2).strip()
      constants[name] = value
    else:
      macro_match = MACRO_PATTERN.match(line)
      if macro_match:
        name = macro_match.group(1)
        args = map(string.strip, macro_match.group(2).split(','))
        body = macro_match.group(3).strip()
        macros[name] = TextMacro(args, body)
      else:
        python_match = PYTHON_MACRO_PATTERN.match(line)
        if python_match:
          name = python_match.group(1)
          args = map(string.strip, python_match.group(2).split(','))
          body = python_match.group(3).strip()
          fun = eval("lambda " + ",".join(args) + ': ' + body)
          macros[name] = PythonMacro(args, fun)
        else:
          raise ("Illegal line: " + line)
  return (constants, macros)


HEADER_TEMPLATE = """\
#ifndef node_natives_h
#define node_natives_h
namespace node {

%(source_lines)s\

struct _native {
  const char* name;
  const char* source;
  size_t source_len;
};

static const struct _native natives[] = {

%(native_lines)s\

  { NULL, NULL } /* sentinel */

};

}
#endif
"""


NATIVE_DECLARATION = """\
  { "%(id)s", %(id)s_native, sizeof(%(id)s_native)-1 },
"""

SOURCE_DECLARATION = """\
  const char %(id)s_native[] = { %(data)s };
"""


GET_DELAY_INDEX_CASE = """\
    if (strcmp(name, "%(id)s") == 0) return %(i)i;
"""


GET_DELAY_SCRIPT_SOURCE_CASE = """\
    if (index == %(i)i) return Vector<const char>(%(id)s, %(length)i);
"""


GET_DELAY_SCRIPT_NAME_CASE = """\
    if (index == %(i)i) return Vector<const char>("%(name)s", %(length)i);
"""

def JS2C(source, target):
  ids = []
  delay_ids = []
  modules = []
  # Locate the macros file name.
  consts = {}
  macros = {}

  for s in source:
    if 'macros.py' == (os.path.split(str(s))[1]):
      (consts, macros) = ReadMacros(ReadLines(str(s)))
    else:
      modules.append(s)

  # Build source code lines
  source_lines = [ ]
  source_lines_empty = []

  native_lines = []

  for s in modules:
    delay = str(s).endswith('-delay.js')
    lines = ReadFile(str(s))
    do_jsmin = lines.find('// jsminify this file, js2c: jsmin') != -1

    lines = ExpandConstants(lines, consts)
    lines = ExpandMacros(lines, macros)
    lines = CompressScript(lines, do_jsmin)
    data = ToCArray(s, lines)
    id = os.path.basename(str(s)).split('.')[0]
    if delay: id = id[:-6]
    if delay:
      delay_ids.append((id, len(lines)))
    else:
      ids.append((id, len(lines)))
    source_lines.append(SOURCE_DECLARATION % { 'id': id, 'data': data })
    source_lines_empty.append(SOURCE_DECLARATION % { 'id': id, 'data': 0 })
    native_lines.append(NATIVE_DECLARATION % { 'id': id })
  
  # Build delay support functions
  get_index_cases = [ ]
  get_script_source_cases = [ ]
  get_script_name_cases = [ ]

  i = 0
  for (id, length) in delay_ids:
    native_name = "native %s.js" % id
    get_index_cases.append(GET_DELAY_INDEX_CASE % { 'id': id, 'i': i })
    get_script_source_cases.append(GET_DELAY_SCRIPT_SOURCE_CASE % {
      'id': id,
      'length': length,
      'i': i
    })
    get_script_name_cases.append(GET_DELAY_SCRIPT_NAME_CASE % {
      'name': native_name,
      'length': len(native_name),
      'i': i
    });
    i = i + 1

  for (id, length) in ids:
    native_name = "native %s.js" % id
    get_index_cases.append(GET_DELAY_INDEX_CASE % { 'id': id, 'i': i })
    get_script_source_cases.append(GET_DELAY_SCRIPT_SOURCE_CASE % {
      'id': id,
      'length': length,
      'i': i
    })
    get_script_name_cases.append(GET_DELAY_SCRIPT_NAME_CASE % {
      'name': native_name,
      'length': len(native_name),
      'i': i
    });
    i = i + 1

  # Emit result
  output = open(str(target[0]), "w")
  output.write(HEADER_TEMPLATE % {
    'builtin_count': len(ids) + len(delay_ids),
    'delay_count': len(delay_ids),
    'source_lines': "\n".join(source_lines),
    'native_lines': "\n".join(native_lines),
    'get_index_cases': "".join(get_index_cases),
    'get_script_source_cases': "".join(get_script_source_cases),
    'get_script_name_cases': "".join(get_script_name_cases)
  })
  output.close()

  if len(target) > 1:
    output = open(str(target[1]), "w")
    output.write(HEADER_TEMPLATE % {
      'builtin_count': len(ids) + len(delay_ids),
      'delay_count': len(delay_ids),
      'source_lines': "\n".join(source_lines_empty),
      'get_index_cases': "".join(get_index_cases),
      'get_script_source_cases': "".join(get_script_source_cases),
      'get_script_name_cases': "".join(get_script_name_cases)
    })
    output.close()

def main():
  natives = sys.argv[1]
  source_files = sys.argv[2:]
  JS2C(source_files, [natives])

if __name__ == "__main__":
  main()

```

`node_natives.h` 文件内容：

```
namespace node {

const char node_native[] = { 47, 47, ..};
const char dgram_native[] = { 47, 47, ..};
const char console_native[] = { 47, 47, ..};
const char buffer_native[] = { 47, 47, ..};
const char querystring_native[] = { 47, 47, ..};
const char punycode_native[] = { 47, 42, ..};
...
struct _native {
const char* name;
const char* source;
size_t source_len;
};

static const struct _native natives[] = {
{ "node", node_native, sizeof(node_native)-1 },
{ "dgram", dgram_native, sizeof(dgram_native)-1 },
...
};
}
```

在这个过程中，JavaScript代码以字符串的形式存储在node命令空间中，是不可直接执行的。在启动Node进程中，JavaScript代码直接加载的内存中。在加载的过程中，JavaScript核心模块经历标识符分析后直接定位到内存中，比普通的文件模块从磁盘中一处一处查找要快很多。

* 编译JavaScript核心模块

lib目录下所有模块文件也没有定义require、module、exports这些变量。在引入JavaScript核心模块的过程中，也经历了头尾包装的过程，然后才执行和导出了exports对象。与文件模块的区别在于：获取源代码的方式(核心模块是从内存中加载的)以及缓存执行结果的位置。

JavaScript核心模块的定义如下面的代码所示，源文件通过process.binding('natives')取出，编译成功的模块缓存到NativeModule.\_cache对象上，文件模块则缓存到Module.\_cache对象上：

```
function NativeModule(id) {
  this.filename = id + '.js';
  this.id = id;
  this.exports = {};
  this.loaded = false;
}
NativeModule._source = procss.binding('natives');
NativeModule._cache = {};
```

* C/C++核心模块的编译过程

在核心模块中，有些模块全部由C/C++编写，有些模块则由C/C++完成核心部分，其他部分则由JavaScript实现包装或者向外导出，以满足性能需求。后面这种C++模块主内完成核心，JavaScript主外完成实现封装的模式是Node能够提高性能的常见方式。

这里我们将那些由纯C/C++编写的部分统一成为内建模块，因为它们通常不被用户直接调用。Node的buffer、crypto、evals、fs、os等模块都是部分通过C/C++编写的。

* 内建模块的组成形式

在Node中，内建模块的内部结构如下：

```
struct node_module_struct {
	int version;
	void *dso_handle;
	const char *filename;
	void (*register_func) (v8::Handle<v8::Object> target);
	const char *modname;
};
```

每一个内建模块在定义之后，都通过NODE_MODULE宏将模块定义到node命名空间中，模块的具体初始化方法挂载为结构的`register_func`成员：

```
#define NODE_MODULE(modname, regfunc)
	extern "C" {
		NODE_MODULE_EXPORT node::node_module_struct modname ## _module =
		{
			NODE_STANDARD_MODULE_STUFF,
			regfunc,
			NODE_STRINGIFY(modname)
		};
	}
```

`node_extensions.h`文件将这些散列的内建模块统一放进了一个叫`node_module_list`的数组中，包括：`node_buffer、node_crypto、node_fs`等。
这些内建模块的取出也十分方便，Node提供了`get_builtin_module()`方法从数组中取出这些模块。

