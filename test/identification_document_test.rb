require_relative 'test_helper'

class IdentificationDocumentTest < Minitest::Test
  def test_alphanumeric_legal_id_is_valid_in_version_44
    id_document = build_id_document("02", "3101A00001")

    builder = Nokogiri::XML::Builder.new
    id_document.build_xml(builder, document_with_version("4.4"))

    assert_includes builder.to_xml,"<Numero>3101A00001</Numero>"
    assert_equal "003101A00001", id_document.id_number
  end

  def test_alphanumeric_legal_id_is_invalid_before_version_44
    ["4.2", "4.3"].each do |version|
      id_document = build_id_document("02", "3101A00001")

      assert_raises(FE::Error) { id_document.build_xml(nil, document_with_version(version)) }
    end
  end

  def test_numeric_legal_id_is_valid_in_every_version
    ["4.2", "4.3", "4.4"].each do |version|
      id_document = build_id_document("02", "3102123456")

      assert id_document.build_xml(nil, document_with_version(version))
    end
  end

  def test_reception_message_infers_alphanumeric_legal_id_in_version_44
    message = FE::ReceptionMessage.new(version: "4.4")

    assert_equal "02", message.send(:infer_id_type, "003101A00001")
  end

  private

  def document_with_version(version)
    document = FE::Invoice.new
    document.version = version
    document
  end
end
