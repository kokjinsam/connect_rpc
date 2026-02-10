defmodule Connect.ProtocolTest do
  use ExUnit.Case, async: true

  alias Connect.Protocol

  defp build_conn(method, content_type) do
    conn = Plug.Test.conn(method, "/")

    if content_type do
      Plug.Conn.put_req_header(conn, "content-type", content_type)
    else
      conn
    end
  end

  # --- parse_content_type/1 ---

  describe "parse_content_type/1" do
    test "unary json" do
      conn = build_conn(:post, "application/json")
      assert {:ok, %{wire_mode: :unary, codec: :json}} = Protocol.parse_content_type(conn)
    end

    test "unary proto" do
      conn = build_conn(:post, "application/proto")
      assert {:ok, %{wire_mode: :unary, codec: :binary}} = Protocol.parse_content_type(conn)
    end

    test "streaming json" do
      conn = build_conn(:post, "application/connect+json")
      assert {:ok, %{wire_mode: :streaming, codec: :json}} = Protocol.parse_content_type(conn)
    end

    test "streaming proto" do
      conn = build_conn(:post, "application/connect+proto")
      assert {:ok, %{wire_mode: :streaming, codec: :binary}} = Protocol.parse_content_type(conn)
    end

    test "unary json with charset is accepted (lenient)" do
      conn = build_conn(:post, "application/json; charset=utf-8")
      assert {:ok, %{wire_mode: :unary, codec: :json}} = Protocol.parse_content_type(conn)
    end

    test "unary proto with charset is accepted (lenient)" do
      conn = build_conn(:post, "application/proto; charset=utf-8")
      assert {:ok, %{wire_mode: :unary, codec: :binary}} = Protocol.parse_content_type(conn)
    end

    test "streaming json with charset is REJECTED (strict)" do
      conn = build_conn(:post, "application/connect+json; charset=utf-8")
      assert {:error, :unsupported_media_type} = Protocol.parse_content_type(conn)
    end

    test "streaming proto with charset is REJECTED (strict)" do
      conn = build_conn(:post, "application/connect+proto; charset=utf-8")
      assert {:error, :unsupported_media_type} = Protocol.parse_content_type(conn)
    end

    test "unknown content type is rejected" do
      conn = build_conn(:post, "text/plain")
      assert {:error, :unsupported_media_type} = Protocol.parse_content_type(conn)
    end

    test "empty content type is rejected" do
      conn = build_conn(:post, nil)
      assert {:error, :unsupported_media_type} = Protocol.parse_content_type(conn)
    end
  end

  # --- validate_method/1 ---

  describe "validate_method/1" do
    test "POST is accepted" do
      conn = Plug.Test.conn(:post, "/")
      assert :ok = Protocol.validate_method(conn)
    end

    test "GET is rejected" do
      conn = Plug.Test.conn(:get, "/")
      assert {:error, :method_not_allowed} = Protocol.validate_method(conn)
    end

    test "PUT is rejected" do
      conn = Plug.Test.conn(:put, "/")
      assert {:error, :method_not_allowed} = Protocol.validate_method(conn)
    end

    test "DELETE is rejected" do
      conn = Plug.Test.conn(:delete, "/")
      assert {:error, :method_not_allowed} = Protocol.validate_method(conn)
    end
  end

  # --- validate_protocol_version/1 ---

  describe "validate_protocol_version/1" do
    test "version 1 is accepted" do
      conn =
        Plug.Test.conn(:post, "/")
        |> Plug.Conn.put_req_header("connect-protocol-version", "1")

      assert :ok = Protocol.validate_protocol_version(conn)
    end

    test "missing version is rejected when required (default)" do
      conn = Plug.Test.conn(:post, "/")
      assert {:error, :unsupported_protocol_version} = Protocol.validate_protocol_version(conn)
    end

    test "missing version is accepted when not required" do
      conn = Plug.Test.conn(:post, "/")
      assert :ok = Protocol.validate_protocol_version(conn, required: false)
    end

    test "version 2 is rejected" do
      conn =
        Plug.Test.conn(:post, "/")
        |> Plug.Conn.put_req_header("connect-protocol-version", "2")

      assert {:error, :unsupported_protocol_version} =
               Protocol.validate_protocol_version(conn)
    end

    test "empty version string is rejected" do
      conn =
        Plug.Test.conn(:post, "/")
        |> Plug.Conn.put_req_header("connect-protocol-version", "")

      assert {:error, :unsupported_protocol_version} =
               Protocol.validate_protocol_version(conn)
    end
  end

  # --- mime_type/1 and stream_mime_type/1 ---

  describe "mime_type/1" do
    test "json" do
      assert "application/json" = Protocol.mime_type(:json)
    end

    test "binary" do
      assert "application/proto" = Protocol.mime_type(:binary)
    end
  end

  describe "stream_mime_type/1" do
    test "json" do
      assert "application/connect+json" = Protocol.stream_mime_type(:json)
    end

    test "binary" do
      assert "application/connect+proto" = Protocol.stream_mime_type(:binary)
    end
  end
end
