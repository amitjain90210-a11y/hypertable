/**
 * Copyright (C) 2007-2016 Hypertable, Inc.
 *
 * This file is part of Hypertable.
 *
 * Hypertable is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 3
 * of the License, or any later version.
 *
 * Hypertable is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Hypertable. If not, see <http://www.gnu.org/licenses/>
 */
#include "Common/Compat.h"

#include "../ThriftBroker/SerializedCellsReader.h"
#include "../ThriftBroker/SerializedCellsWriter.h"

#include <boost/python.hpp>
#include <boost/python/make_constructor.hpp>

using namespace Hypertable;
using namespace boost::python;

typedef bool (SerializedCellsWriter::*addfn)(const char *row,
                const char *column_family, const char *column_qualifier,
                int64_t timestamp, const char *value, int32_t value_length,
                int cell_flag);
typedef const char *(SerializedCellsWriter::*getfn)();
typedef int32_t (SerializedCellsWriter::*getlenfn)();

static addfn afn = &Hypertable::SerializedCellsWriter::add;
static getlenfn lenfn = &Hypertable::SerializedCellsWriter::get_buffer_length;

static PyObject *convert(const SerializedCellsWriter &scw) {
  boost::python::object obj(handle<>(PyMemoryView_FromMemory(
                      (char *)scw.get_buffer(), scw.get_buffer_length(), PyBUF_READ)));
  return boost::python::incref(obj.ptr());
}

// Python 3 bytes objects don't auto-convert to const char* in Boost.Python
static SerializedCellsReader *scr_make(boost::python::object buf_obj, uint32_t len) {
  if (!PyBytes_Check(buf_obj.ptr())) {
    PyErr_SetString(PyExc_TypeError, "first argument must be bytes");
    boost::python::throw_error_already_set();
  }
  return new SerializedCellsReader(PyBytes_AsString(buf_obj.ptr()), len);
}

// Return value as bytes with exact length to avoid reading past the buffer
static boost::python::object scr_value_bytes(SerializedCellsReader &scr) {
  return boost::python::object(
      handle<>(PyBytes_FromStringAndSize(
          static_cast<const char *>(scr.value()), scr.value_len())));
}

BOOST_PYTHON_MODULE(libHyperPython)
{

  class_<Cell>("Cell")
    .def("sanity_check", &Cell::sanity_check)
    .def_readwrite("row", &Cell::row_key)
    .def_readwrite("column_family", &Cell::column_family)
    .def_readwrite("column_qualifier", &Cell::column_qualifier)
    .def_readwrite("timestamp", &Cell::timestamp)
    .def_readwrite("revision", &Cell::revision)
    .def_readwrite("value", &Cell::value)
    .def_readwrite("flag", &Cell::flag)
    .def(self_ns::str(self_ns::self))
    ;

  class_<SerializedCellsReader>("SerializedCellsReader", boost::python::no_init)
    .def("__init__", boost::python::make_constructor(&scr_make))
    .def("has_next", &SerializedCellsReader::next)
    .def("get_cell", &SerializedCellsReader::get_cell,
          return_value_policy<return_by_value>())
    .def("row", &SerializedCellsReader::row,
          return_value_policy<return_by_value>())
    .def("column_family", &SerializedCellsReader::column_family,
          return_value_policy<return_by_value>())
    .def("column_qualifier", &SerializedCellsReader::column_qualifier,
          return_value_policy<return_by_value>())
    .def("value", &scr_value_bytes)
    .def("value_len", &SerializedCellsReader::value_len)
    .def("value_str", &scr_value_bytes)
    .def("timestamp", &SerializedCellsReader::timestamp)
    .def("cell_flag", &SerializedCellsReader::cell_flag)
    .def("flush", &SerializedCellsReader::flush)
    .def("eos", &SerializedCellsReader::eos)
  ;

  class_<SerializedCellsWriter, boost::noncopyable>("SerializedCellsWriter",
          init<int32_t, bool>())
    .def("add", afn)
    .def("finalize", &SerializedCellsWriter::finalize)
    .def("empty", &SerializedCellsWriter::empty)
    .def("clear", &SerializedCellsWriter::clear)
    .def("__len__", lenfn)
    .def("get", &convert)
  ;
}
