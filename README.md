# can-transceiver-lib
Generates a cpp library from a DBC file using the cantools DBC parser and extended generator.

# Install

## cantools extended generator

1. Get the extended generator

        git clone --branch extend_codegen https://github.com/rimakoe/cantools.git

1. Install it in your python using 

        pip install -e ./path/to/cantools

1. Verify the installation with

        pip freeze

    You should see something like 

        -e <some local cantool link>

## transceiver library

1. Now we can build the can transceiver library

        git clone https://github.com/rimakoe/can-transceiver-lib.git

1. Change directory inside the repo

        cd can-transceiver-lib

1. Put your dbc file into the dbc folder.

1. Create a build folder inside the repo and go into it

        mkdir build && cd build

1. Use cmake to build and install the library

        cmake .. && sudo make install

Now you are able to link the library in every c++ project.

## Link the library

In your CMakeLists.txt use

    find_package(can-transceiver-lib REQURIED)
    target_link_libraries(${TARGET_NAME} canlib::can-transceiver-lib)

Thats all for standard cmake.

If you are using ROS make sure to use the cmake standard link path with

    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

## Usage

As an example a ROS node is cerated, but you can use it equivalently in any other c++ class. You can look at the [playground](https://github.com/rimakoe/can-transceiver-playground) for reference.

### **Init** 

The idea is to inherit from the canlib::Transceiver. The constructor needs the device name and the filters. Of course you dont explicitly need to inherit and can use the class as it is and create an instance of the Transceiver object.

```(c++)
class TestNode : public rclcpp::Node, canlib::Transceiver {
 public:
  TestNode();
  TestNode(std::string device_name, std::vector<can_filter> filters);
  ~TestNode();

 private:
  bool is_receiver_running = false;
  bool is_transmitter_running = false;
};
```


```(c++)
// Setup filters
std::vector<can_filter> filters;
can_filter filter;
filter.can_id = 0x0E2;
filter.can_mask = CAN_SFF_MASK;
filters.push_back(filter);
filter.can_id = 0x0E1;
filter.can_mask = CAN_SFF_MASK;
filters.push_back(filter);
// Set device name
std::string device_name = "vcan0";
// Start ROS Node
rclcpp::spin(std::make_shared<TestNode>(device_name, filters));
```


### **Receive** 

Inside your transceiver you have to call the *receive* function regularly to receive can messages. It waits for a certain amount of time on every call, but does not listen continuosly. Manage it in some way, e.g. put it into a thread and manage your thread properly.

For safety reasons we use a mutex here aswell.

```
std::thread receiver([this]() {
    RCLCPP_INFO(this->get_logger(), "starting CAN receiver ...");
    while (rclcpp::ok()) {
        mtx.lock();
        if (receive()) {
            RCLCPP_INFO(this->get_logger(), "received data");
        }
        mtx.unlock();
    }
    RCLCPP_INFO(this->get_logger(), "shutdown CAN receiver ...");
    });
receiver.detach();
```

Once you received data from a desired CAN ID, the corresponding callback is called. Fill in your desired actions e.g. update your member variables.

```
canlib::callback::can1::jetson_commands = [&](can1_jetson_commands_t /*frame_encoded*/,                                                   canlib::frame::decoded::can1::jetson_commands_t frame_decoded) {
    RCLCPP_INFO(this->get_logger(), "received jetson_commands: brake ratio = %lf", frame_decoded.jetson_brake_ratio);
    m_brake_ratio = frame_decoded.jetson_brake_ratio;
    };
```

### **Transmit** 

The transceiver has a very hard overloaded transmit function. Just pass it you desired message frame and it will take care of the encoding and sending for you. So you just want to call e.g.

```
transmit(canlib::frame::decoded::can1::jetson_commands_t(0.1, 0.2, 0.3, 0.4, 0.5));
```
If your IDE is setup correctly, you have autocomplete help to fill in the constructor of the struct. Thus you know exactly what every part of the frame represents.