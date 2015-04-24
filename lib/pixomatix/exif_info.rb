module Pixomatix
  class ExifInfo
    def initialize(file)
      @image_path = file
      @result = Exiftool.new(file).results.first
    end

    def print_fields
      self.class.field_map.each do |id, name|
        p [ name, @result.raw[id] ]
      end
      nil
    end

    def print_raw
      @result.raw.each{ |k, v| p [k, v] }
      nil
    end

    def self.field_map
      {
        make: 'Camera Make',
        model: 'Camera Model',
        lens_id: 'Lens ID',
        lens_spec: 'Lens Specification',
        focal_length: 'Focal Length',
        focal_length_in35mm_format: 'Focal Length In 35mm Format',
        scale_factor35efl: 'Scale Factor To 35mm Format',
        shutter_speed: 'Shutter Speed (Exposure Time)',
        exposure_time: 'Exposure Time (Shutter Speed)',
        exposure_mode: 'Exposure Mode',
        exposure_program: 'Exposure Program',
        exposure_compensation: 'Exposure Compensation',
        auto_focus: 'Auto Focus',
        focus_mode: 'Focus Mode',
        focus_distance: 'Focus Distance',
        af_assist: 'Auto Focus Assist',
        af_area_mode: 'Auto Focus Area Mode',
        f_number: 'F Number (Aperture)',
        orientation: 'Orientation',
        x_resolution: 'X Resolution',
        y_resolution: 'Y Resolution',
        resolution_unit: 'Resolution Units',
        image_width: 'Width',
        image_height: 'Height',
        image_data_size: 'Size',
        file_type: 'File Type',
        mime_type: 'Mime Type',
        color_space: 'Color Space',
        digital_zoom_ratio: 'Digital Zoom Ratio',
        date_time_original: 'Date Time Original',
        timezone: 'Timezone',
        iso: 'ISO Sensitivity',
        iso_setting: 'ISO Setting',
        metering_mode: 'Metering Mode',
        light_source: 'Light Source',
        flash: 'Flash',
        flash_setting: 'Flash Settings',
        flash_type: 'Flash Type',
        flash_mode: 'Flash Mode',
        quality: 'Quality',
        white_balance: 'White Balance',
        compression: 'Compression',
        vibration_reduction: 'Vibration Reduction',
        vr_mode: 'VR Mode',
        "active_d-lighting": 'Active D Lighting',
        hdr: 'HDR',
        hdr_level: 'HDR Level',
        hdr_smoothing: 'HDR Smoothing',
        shooting_mode: 'Shooting Mode',
        noise_reduction: 'Noise Reduction',
        user_comment: 'Comment',
      }
    end
  end
end
