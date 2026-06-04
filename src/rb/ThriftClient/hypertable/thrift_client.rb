# include path hack
$:.push(File.dirname(__FILE__) + '/gen-rb')

require 'thrift'
require 'thrift/protocol/binary_protocol_accelerated'

# Thrift 0.19.0 generated code calls receive_message_begin() and reply_seqid()
# which don't exist in the 0.16.0 gem.  It also expects receive_message() to
# read only the result struct (header already consumed by receive_message_begin).
# Add these shims so the generated code works against the older runtime.
unless ::Thrift::Client.method_defined?(:receive_message_begin)
  module ::Thrift
    module Client
      def receive_message_begin
        @iprot.read_message_begin
      end

      def reply_seqid(_rseqid)
        true
      end

      def receive_message(result_klass)
        result = result_klass.new
        result.read(@iprot)
        @iprot.read_message_end
        result
      end
    end
  end
end

require 'hql_service'

module Hypertable
  class ThriftClient < ThriftGen::HqlService::Client
    def initialize(host, port, timeout_ms = 300000, do_open = true)
      socket = Thrift::Socket.new(host, port, timeout_ms)
      @transport = Thrift::FramedTransport.new(socket)
      protocol = Thrift::BinaryProtocolAccelerated.new(@transport)
      super(protocol)
      open() if do_open
    end

    def open()
      @transport.open()
      @do_close = true
    end

    def close()
      @transport.close() if @do_close
    end

    # more convenience methods
    def with_future(queue_size = 0)
      future = open_future(queue_size)
      begin
        yield future 
      ensure
        close_future(future)
      end
    end

    def with_scanner(namespace, table, scan_spec)
      scanner = open_scanner(namespace, table, scan_spec)
      begin
        yield scanner
      ensure
        close_scanner(scanner)
      end
    end

    def with_mutator(namespace, table)
      mutator = open_mutator(namespace, table, 0, 0);
      begin
        yield mutator
      ensure
        close_mutator(mutator)
      end
    end

    # scanner iterator
    def each_cell(scanner)
      cells = next_cells(scanner);

      while (cells.size > 0)
        cells.each {|cell| yield cell}
        cells = next_cells(scanner);
      end
    end
  end

  def self.with_thrift_client(host, port, timeout_ms = 20000)
    client = ThriftClient.new(host, port, timeout_ms)
    begin
      yield client
    ensure
      client.close()
    end
  end

  module ThriftGen
    class Key
      def to_s
        "{Key row=%s column_family=%s column_qualifier=%s flag=%s}" %
          [row, column_family, column_qualifier, flag]
      end
    end
    class Cell
      def to_s
        "{Cell key=%s value=%s}" % [key, value]
      end
    end
  end

end
