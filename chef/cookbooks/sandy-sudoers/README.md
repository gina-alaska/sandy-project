# sandy-sudoers-cookbook

TODO: Enter the cookbook description here.

## Supported Platforms

TODO: List your supported platforms.

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['sandy-sudoers']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### sandy-sudoers::default

Include `sandy-sudoers` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[sandy-sudoers::default]"
  ]
}
```

## License and Authors

Author:: UAF-GINA (<support+chef@gina.alaska.edu>)
