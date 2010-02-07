require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ForwardedPortTest < Test::Unit::TestCase
  setup do
    @caller = mock("caller")
  end

  context "validations" do
    setup do
      @port = VirtualBox::ForwardedPort.new
      @port.name = "foo"
      @port.guestport = "22"
      @port.hostport = "2222"
      @port.added_to_relationship(@caller)
    end

    should "be valid with all fields" do
      assert @port.valid?
    end

    should "be invalid with no name" do
      @port.name = nil
      assert !@port.valid?
    end

    should "be invalid with no guest port" do
      @port.guestport = nil
      assert !@port.valid?
    end

    should "be invalid with no host port" do
      @port.hostport = nil
      assert !@port.valid?
    end

    should "be invalid if not in a relationship" do
      @port.write_attribute(:parent, nil)
      assert !@port.valid?
    end
  end

  context "with an instance" do
    setup do
      @port = VirtualBox::ForwardedPort.new({
        :parent => @caller,
        :name => "foo",
        :guestport => "22",
        :hostport => "2222"
      })

      @ed = mock("extradata")
      @ed.stubs(:[]=)
      @ed.stubs(:save)
      @ed.stubs(:delete)
      @caller.stubs(:extra_data).returns(@ed)
    end

    context "saving" do
      context "an existing record" do
        setup do
          @port.existing_record!
        end

        should "not do anything and return true if its unchanged" do
          @caller.expects(:extra_data).never
          assert @port.save
        end

        should "clear the dirty state after saving" do
          @port.name = "diff"
          @port.save
          assert !@port.changed?
        end

        should "call destroy if the name changed" do
          @port.name = "diff"
          @port.expects(:destroy).once
          @port.save
        end

        should "not call destroy if the name didn't change" do
          assert !@port.name_changed?
          @port.expects(:destroy).never
          @port.save
        end
      end

      context "a new record" do
        setup do
          assert @port.new_record!
        end

        should "no longer be a new record after saving" do
          @port.save
          assert !@port.new_record?
        end

        should "return false and do nothing if invalid" do
          @caller.expects(:extra_data).never
          @port.expects(:valid?).returns(false)
          assert !@port.save
        end

        should "raise a ValidationFailedException if invalid and raise_errors is true" do
          @port.expects(:valid?).returns(false)
          assert_raises(VirtualBox::Exceptions::ValidationFailedException) {
            @port.save(true)
          }
        end

        should "call save on the extra_data" do
          @ed = mock("ed")
          @ed.expects(:[]=).times(3)
          @ed.expects(:save).once
          @caller.expects(:extra_data).times(4).returns(@ed)
          @port.save
        end
      end
    end

    context "key prefix" do
      should "return a proper key prefix constructed with the attributes" do
        assert_equal "VBoxInternal\/Devices\/#{@port.device}\/#{@port.instance}\/LUN#0\/Config\/#{@port.name}\/", @port.key_prefix
      end

      should "return with previous name if parameter is true" do
        @port.name = "diff"
        assert @port.name_changed?
        assert_equal "VBoxInternal\/Devices\/#{@port.device}\/#{@port.instance}\/LUN#0\/Config\/#{@port.name_was}\/", @port.key_prefix(true)
      end

      should "not use previous name if parameter is true and name didn't change" do
        assert !@port.name_changed?
        assert_equal "VBoxInternal\/Devices\/#{@port.device}\/#{@port.instance}\/LUN#0\/Config\/#{@port.name}\/", @port.key_prefix(true)
      end
    end

    context "destroying" do
      setup do
        @port.existing_record!
      end

      should "call delete on the extra data for each key" do
        @ed = mock("ed")
        @ed.expects(:delete).times(3)
        @caller.expects(:extra_data).times(3).returns(@ed)
        @port.destroy
      end

      should "do nothing if the record is new" do
        @port.new_record!
        @caller.expects(:extra_data).never
        @port.destroy
      end

      should "be a new record after destroying" do
        @port.destroy
        assert @port.new_record?
      end
    end
  end

  context "relationships" do
    context "saving" do
      should "call #save on every object" do
        objects = []
        5.times do |i|
          object = mock("object#{i}")
          object.expects(:save).once
          objects.push(object)
        end

        VirtualBox::ForwardedPort.save_relationship(@caller, objects)
      end
    end

    context "populating" do
      setup do
        @caller.stubs(:extra_data).returns({
          "invalid" => "7",
          "VBoxInternal/Devices/pcnet/0/LUN#0/Config/guestssh/GuestPort" => "22",
          "VBoxInternal/Devices/pcnet/0/LUN#0/Config/guestssh/HostPort" => "2222",
          "VBoxInternal/Devices/pcnet/0/LUN#0/Config/guestssh/Protocol" => "TCP"
        })

        @objects = VirtualBox::ForwardedPort.populate_relationship(@caller, {})
      end

      should "return an array of ForwardedPorts" do
        assert @objects.is_a?(VirtualBox::Proxies::Collection)
        assert @objects.all? { |o| o.is_a?(VirtualBox::ForwardedPort) }
      end

      should "have the proper data" do
        object = @objects.first
        assert_equal "22", object.guestport
        assert_equal "2222", object.hostport
        assert_equal "TCP", object.protocol
      end

      should "be existing records" do
        assert !@objects.first.new_record?
      end
    end
  end
end